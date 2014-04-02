require 'dep_selector'
require 'set'

module Solve
  class GecodeSolver

    attr_reader :graph
    attr_reader :demands

    # DepSelector::DependencyGraph object representing the problem.
    attr_reader :ds_graph

    # Timeout in milliseconds. Hardcoded to 1s for now.
    attr_reader :timeout_ms

    private :ds_graph
    private :timeout_ms

    def initialize(graph, demands, ui=nil)
      @ds_graph = DepSelector::DependencyGraph.new
      @graph = graph
      @demands = demands
      @timeout_ms = 1_000
    end

    def resolve(options={})
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

    def debug_demands
      puts "debugging invalid solution, hang on..."

      bad_demands_indices = []
      viable_demands = nil

      1.upto(demands.size) do |i|
        trial_demands = demands_as_constraints[0,i]
        bad_demands_indices.each {|bad_index| trial_demands.delete_at(bad_index) }

        begin

          solve_demands(trial_demands)
          viable_demands = trial_demands
        rescue Solve::Errors::NoSolutionError => e
          puts "Demand conflicts: #{trial_demands.last} (#{e})"
          # this has to be reverse sorted or else we'll delete the wrong
          # demands when interating
          bad_demands_indices.unshift(i - 1)
        end
      end
      viable_demands_to_report = viable_demands.map {|d| d.to_s }
      puts "These cookbooks are ok:"
      viable_demands_to_report.each {|d| puts "  " + d }
    end

    private

      def demands_as_constraints
        @demands_as_constraints ||= demands.map do |demands_item|
          item_name, constraint_with_operator = demands_item
          version_constraint = Constraint.new(constraint_with_operator)
          DepSelector::SolutionConstraint.new(ds_graph.package(item_name), version_constraint)
        end
      end

      def all_artifacts
        return @all_artifacts if @all_artifacts
        populate_ds_graph!
        @all_artifacts
      end

      # TODO :private
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


      def solve_demands(demands_as_constraints)
        selector = DepSelector::Selector.new(ds_graph, (timeout_ms / 1000.0))
        selector.find_solution(demands_as_constraints, all_artifacts)
      rescue DepSelector::Exceptions::InvalidSolutionConstraints => e
        report_invalid_constraints_error(e)
      rescue DepSelector::Exceptions::NoSolutionExists => e
        report_no_solution_error(e)
      rescue DepSelector::Exceptions::TimeBoundExceeded,
             DepSelector::Exceptions::TimeBoundExceededNoSolution => e
        # While dep_selector differentiates between the two solutions, the opscode-chef
        # API returns the same error regardless of the timeout type. We'll swallow the
        # difference here and return a unified timeout to erchef
        raise Solve::Errors::NoSolutionError.new("resolution_timeout: #{e.class} - #{e.message}")
      end


      def report_invalid_constraints_error(e)
        non_existent_cookbooks = e.non_existent_packages.inject([]) do |list, constraint|
          list << constraint.package.name
        end

        constrained_to_no_versions = e.constrained_to_no_versions.inject([]) do |list, constraint|
          list << constraint.to_s
        end

        error_detail = [[:non_existent_cookbooks, non_existent_cookbooks],
                                      [:constraints_not_met, constrained_to_no_versions]]

        raise Solve::Errors::NoSolutionError.new([:invalid_constraints, error_detail].inspect)
      end

      def report_no_solution_error(e)
        most_constrained_cookbooks = e.disabled_most_constrained_packages.inject([]) do |list, package|
          # WTF: this is the reported error format but I can't find this anywhere in the ruby code
          list << "#{package.name} = #{package.versions.first.to_s}"
        end

        non_existent_cookbooks = e.disabled_non_existent_packages.inject([]) do |list, package|
          list << package.name
        end

        error_detail = [[:message, e.message],
                                      [:unsatisfiable_demand, e.unsatisfiable_solution_constraint.to_s],
                                      [:non_existent_cookbooks, non_existent_cookbooks],
                                      [:most_constrained_cookbooks, most_constrained_cookbooks]]

        raise Solve::Errors::NoSolutionError.new([:no_solution, error_detail].inspect)
      end

      def build_sorted_solution(unsorted_solution)
        nodes = Hash.new
        unsorted_solution.each do |name, version|
          nodes[name] = @graph.get_artifact(name, version).dependencies.map(&:name)
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
