require 'dep_selector'

module Solve
  class GecodeSolver

    # The Solve::Graph object for this problem
    attr_reader :solve_graph

    attr_reader :demands
    attr_reader :timeout_ms

    #  Solver.new(graph, demands, options[:ui]).resolve(options)
    #  Solve.it!(graph, [['nginx', '= 1.0.0'], ['mysql']])
    def initialize(solve_graph, demands, ui=nil)
      @solve_graph = solve_graph
      @demands = demands
      @timeout_ms = 1_000
    end

    # The DepSelector::DependencyGraph for this problem
    def graph
      @graph ||= DepSelector::DependencyGraph.new
    end

    # Dumps problem to ruby data structures so it can be used in benchmarks
    def dump_problem
      require 'pp'
      puts "DEMANDS = "
      pp demands.map {|d| d.map {|item| item.to_s} }

      puts "ARTIFACTS = "

      artifacts_by_name =
        solve_graph.artifacts.inject({}) do |by_name, artifact|
          by_name[artifact.name] ||= []
          artifact_info = {:name => artifact.name, :version => artifact.version.to_s}
          artifact_info[:dependencies] = artifact.dependencies.map {|d| [d.name, d.constraint.to_s ] }
          by_name[artifact.name] << artifact_info
          by_name
        end
      pp artifacts_by_name
    end

    def gecode_demands
      @gecode_demands ||= demands.map do |demands_item|
        item_name, constraint_with_operator = demands_item
        version_constraint = Constraint.new(constraint_with_operator)
        DepSelector::SolutionConstraint.new(graph.package(item_name), version_constraint)
      end
    end

    def gecode_all_versions
      return @gecode_all_versions if @gecode_all_versions

      @gecode_all_versions = []

      artifacts_by_name =
        solve_graph.artifacts.inject({}) do |by_name, artifact|
          by_name[artifact.name] ||= []
          by_name[artifact.name] << artifact
          by_name
        end

      artifacts_by_name.each do |name, artifacts|
        add_artifact_to_graph(name, artifacts)
        @gecode_all_versions << graph.package(name)
      end
    end


    def add_artifact_to_graph(name, artifacts)
      artifacts.each do |artifact|
        version = artifact.version
        constraints = artifact.dependencies

        package_version = graph.package(name).add_version(Version.new(version))
        constraints.each do |dependency|
          dep_constraint_str = dependency.constraint.to_s
          version_constraint = Constraint.new(dep_constraint_str)
          dependency = DepSelector::Dependency.new(graph.package(dependency.name), version_constraint)
          package_version.dependencies << dependency
        end
      end

    end

    def resolve_with_benchmark(options={})
      answer = nil
      error = nil
      require 'benchmark'
      Benchmark.bm(7) do |x|
        x.report("solve:") do
          begin
            answer = resolve_without_bm(options)
          rescue => e
            error = e
          end
        end
      end
      raise error if error
      answer
    end

    def resolve(options={})
      solution = solve_demands(gecode_demands)

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


    def solve_demands(gecode_demands)
      selector = DepSelector::Selector.new(graph, (timeout_ms / 1000.0))
      selector.find_solution(gecode_demands, gecode_all_versions)
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

    def debug_demands
      puts "debugging invalid solution, hang on..."

      bad_demands_indices = []
      viable_demands = nil

      1.upto(demands.size) do |i|
        trial_demands = gecode_demands[0,i]
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

    # TODO: copypasta is bad mmkay.
    def build_sorted_solution(unsorted_solution)
      nodes = Hash.new
      unsorted_solution.each do |name, version|
        nodes[name] = @solve_graph.get_artifact(name, version).dependencies.map(&:name)
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
