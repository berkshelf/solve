require 'dep_selector'
require 'set'
require_relative 'solver/serializer'

module Solve
  class Solver
    class << self
      # The timeout (in seconds) to use when resolving graphs. Default is 10. This can be
      # configured by setting the SOLVE_TIMEOUT environment variable.
      #
      # @return [Integer]
      def timeout
        seconds = 30 unless seconds = ENV["SOLVE_TIMEOUT"]
        seconds.to_i * 1_000
      end
    end

    # Graph object with references to all known artifacts and dependency
    # constraints.
    #
    # @return [Solve::Graph]
    attr_reader :graph

    # @example Demands are Arrays of Arrays with an artifact name and optional constraint:
    #   [['nginx', '= 1.0.0'], ['mysql']]
    # @return [Array<String>, Array<Array<String, String>>] demands
    attr_reader :demands_array

    # @example Basic use:
    #   graph = Solve::Graph.new
    #   graph.artifacts("mysql", "1.2.0")
    #   demands = [["mysql"]]
    #   Solver.new(graph, demands)
    # @param [Solve::Graph] graph
    # @param [Array<String>, Array<Array<String, String>>] demands
    def initialize(graph, demands)
      @ds_graph      = DepSelector::DependencyGraph.new
      @graph         = graph
      @demands_array = demands
      @timeout_ms    = self.class.timeout
    end

    # The problem demands given as Demand model objects
    # @return [Array<Solve::Demand>]
    def demands
      demands_array.map do |name, constraint|
        Demand.new(self, name, constraint)
      end
    end

    # @option options [Boolean] :sorted
    #   return the solution as a sorted list instead of a Hash
    #
    # @return [Hash, List] Returns a hash like { "Artifact Name" => "Version",... }
    #   unless the :sorted option is true, then it returns a list like [["Artifact Name", "Version],...]
    # @raise [Errors::NoSolutionError] when the demands cannot be met for the
    #   given graph.
    # @raise [Errors::UnsortableSolutionError] when the :sorted option is true
    #   and the demands have a solution, but the solution contains a cyclic
    #   dependency
    def resolve(options = {})
      solution = solve_demands(demands_as_constraints)

      unsorted_solution = solution.inject({}) do |stringified_soln, (name, version)|
        stringified_soln[name] = version.to_s
        stringified_soln
      end

      if options[:sorted]
        build_sorted_solution(unsorted_solution)
      else
        unsorted_solution
      end
    end

    private

      # DepSelector::DependencyGraph object representing the problem.
      attr_reader :ds_graph

      # Timeout in milliseconds. Hardcoded to 1s for now.
      attr_reader :timeout_ms

      # Runs the solver with the set of demands given. If any DepSelector
      # exceptions are raised, they are rescued and re-raised
      def solve_demands(demands_as_constraints)
        selector = DepSelector::Selector.new(ds_graph, (timeout_ms / 1000.0))
        selector.find_solution(demands_as_constraints, all_artifacts)
      rescue DepSelector::Exceptions::InvalidSolutionConstraints => e
        report_invalid_constraints_error(e)
      rescue DepSelector::Exceptions::NoSolutionExists => e
        report_no_solution_error(e)
      rescue DepSelector::Exceptions::TimeBoundExceeded
        # DepSelector timed out trying to find the solution. There may or may
        # not be a solution.
        raise Solve::Errors::NoSolutionError.new(
          "The dependency constraints could not be solved in the time allotted.")
      rescue DepSelector::Exceptions::TimeBoundExceededNoSolution
        # DepSelector determined there wasn't a solution to the problem, then
        # timed out trying to determine which constraints cause the conflict.
        raise Solve::Errors::NoSolutionCauseUnknown.new(
          "There is a dependency conflict, but the solver could not determine the precise cause in the time allotted.")
      end

      # Maps demands to corresponding DepSelector::SolutionConstraint objects.
      def demands_as_constraints
        @demands_as_constraints ||= demands_array.map do |demands_item|
          item_name, constraint_with_operator = demands_item
          version_constraint = Semverse::Constraint.new(constraint_with_operator)
          DepSelector::SolutionConstraint.new(ds_graph.package(item_name), version_constraint)
        end
      end

      # Maps all artifacts in the graph to DepSelector::Package objects. If not
      # already done, artifacts are added to the ds_graph as a necessary side effect.
      def all_artifacts
        return @all_artifacts if @all_artifacts
        populate_ds_graph!
        @all_artifacts
      end

      # Converts artifacts to DepSelector::Package objects and adds them to the
      # DepSelector graph. This should only be called once; use #all_artifacts
      # to safely get the set of all artifacts.
      def populate_ds_graph!
        @all_artifacts = Set.new

        graph.artifacts.each do |artifact|
          add_artifact_to_ds_graph(artifact)
          @all_artifacts << ds_graph.package(artifact.name)
        end
      end

      def add_artifact_to_ds_graph(artifact)
        package_version = ds_graph.package(artifact.name).add_version(artifact.version)
        artifact.dependencies.each do |dependency|
          dependency = DepSelector::Dependency.new(ds_graph.package(dependency.name), dependency.constraint)
          package_version.dependencies << dependency
        end
        package_version
      end

      def report_invalid_constraints_error(e)
        non_existent_cookbooks = e.non_existent_packages.inject([]) do |list, constraint|
          list << constraint.package.name
        end

        constrained_to_no_versions = e.constrained_to_no_versions.inject([]) do |list, constraint|
          list << [constraint.package.name, constraint.constraint.to_s]
        end

        raise Solve::Errors::NoSolutionError.new(
          "Required artifacts do not exist at the desired version",
          missing_artifacts: non_existent_cookbooks,
          constraints_excluding_all_artifacts: constrained_to_no_versions
        )
      end

      def report_no_solution_error(e)
        most_constrained_cookbooks = e.disabled_most_constrained_packages.inject([]) do |list, package|
          list << "#{package.name} = #{package.versions.first.to_s}"
        end

        non_existent_cookbooks = e.disabled_non_existent_packages.inject([]) do |list, package|
          list << package.name
        end

        raise Solve::Errors::NoSolutionError.new(
          e.message,
          unsatisfiable_demand: e.unsatisfiable_solution_constraint.to_s,
          missing_artifacts: non_existent_cookbooks,
          artifacts_with_no_satisfactory_version: most_constrained_cookbooks
        )
      end

      def build_sorted_solution(unsorted_solution)
        nodes = Hash.new
        unsorted_solution.each do |name, version|
          nodes[name] = @graph.artifact(name, version).dependencies.map(&:name)
        end

        # Modified from http://ruby-doc.org/stdlib-1.9.3/libdoc/tsort/rdoc/TSort.html
        class << nodes
          include TSort
          alias tsort_each_node each_key
          def tsort_each_child(node, &block)
            fetch(node).each(&block)
          end
        end
        begin
          sorted_names = nodes.tsort
        rescue TSort::Cyclic => e
          raise Solve::Errors::UnsortableSolutionError.new(e, unsorted_solution)
        end

        sorted_names.map do |artifact|
          [artifact, unsorted_solution[artifact]]
        end
      end
  end
end
