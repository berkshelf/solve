require 'set'
require 'molinillo'
require_relative 'solver/serializer'

module Solve
  class RubySolver
    class << self
      # The timeout (in seconds) to use when resolving graphs. Default is 10. This can be
      # configured by setting the SOLVE_TIMEOUT environment variable.
      #
      # @return [Integer]
      def timeout
        seconds = 30 unless seconds = ENV["SOLVE_TIMEOUT"]
        seconds.to_i * 1_000
      end

      # For optinal solver engines, this attempts to load depenencies. The
      # RubySolver is a non-optional component, so this is a no-op
      def activate
        true
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
    #   RubySolver.new(graph, demands)
    # @param [Solve::Graph] graph
    # @param [Array<String>, Array<Array<String, String>>] demands
    def initialize(graph, demands, options = {})
      @graph         = graph
      @demands_array = demands
      @timeout_ms    = self.class.timeout

      @ui = options[:ui] # could be nil, but that's okay
      @dependency_source = options[:dependency_source] || 'user-specified dependency'

      @molinillo_graph = Molinillo::DependencyGraph.new
      @resolver = Molinillo::Resolver.new(self, self)
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
      @ui = options[:ui] if options[:ui]

      solved_graph = resolve_with_error_wrapping

      solution =  solved_graph.map(&:payload)

      unsorted_solution = solution.inject({}) do |stringified_soln, artifact|
        stringified_soln[artifact.name] = artifact.version.to_s
        stringified_soln
      end

      if options[:sorted]
        build_sorted_solution(unsorted_solution)
      else
        unsorted_solution
      end
    end

    ###
    # Molinillo Callbacks
    #
    # Molinillo calls back to this class to get information about our
    # dependency model objects. An abstract implementation is provided at
    # https://github.com/CocoaPods/Molinillo/blob/master/lib/molinillo/modules/specification_provider.rb
    #
    ###

    # Callback required by Molinillo, called when the solve starts
    # @return [Integer]
    def progress_rate
      1
    end

    # Callback required by Molinillo, called when the solve starts
    # @return nil
    def before_resolution
      @ui.say('Starting dependency resolution') if @ui
    end

    # Callback required by Molinillo, called when the solve is complete.
    # @return nil
    def after_resolution
      @ui.say('Finished dependency resolution') if @ui
    end

    # Callback required by Molinillo, called when resolving every progress_rate
    # @return nil
    def indicate_progress
      nil
    end

    # Callback required by Molinillo, gives debug information about the solution
    # @return nil
    def debug(current_resolver_depth)
      # debug info will be returned if you call yield here, but it seems to be
      # broken in current Molinillo
      @ui.say(yield) if @ui
    end

    # Callback required by Molinillo
    # @return [String] the dependency's name
    def name_for(dependency)
      dependency.name
    end

    # Callback required by Molinillo
    # @return [Array<Solve::Dependency>] the dependencies sorted by preference.
    def sort_dependencies(dependencies, activated, conflicts)
      dependencies.sort_by do |dependency|
        name = name_for(dependency)
        [
          activated.vertex_named(name).payload ? 0 : 1,
          conflicts[name] ? 0 : 1,
          activated.vertex_named(name).payload ? 0 : graph.versions(dependency.name).count,
        ]
      end
    end

    # Callback required by Molinillo
    # @return [Array<Solve::Artifact>] the artifacts that match the dependency.
    def search_for(dependency)
      # This array gets mutated by Molinillo; it's okay because sort returns a
      # new array.
      graph.versions(dependency.name, dependency.constraint).sort
    end

    # Callback required by Molinillo
    # @return [Boolean]
    def requirement_satisfied_by?(requirement, activated, spec)
      requirement.constraint.satisfies?(spec.version)
    end

    # Callback required by Molinillo
    # @return [Array<Solve::Dependency>] the dependencies of the given artifact
    def dependencies_for(specification)
      specification.dependencies
    end

    # @return [String] the name of the source of explicit dependencies, i.e.
    #   those passed to {Resolver#resolve} directly.
    def name_for_explicit_dependency_source
      @dependency_source
    end

    # @return [String] the name of the source of 'locked' dependencies, i.e.
    #   those passed to {Resolver#resolve} directly as the `base`
    def name_for_locking_dependency_source
      'Lockfile'
    end

    # Returns whether this dependency, which has no possible matching
    # specifications, can safely be ignored.
    #
    # @param [Object] dependency
    # @return [Boolean] whether this dependency can safely be skipped.
    def allow_missing?(dependency)
      false
    end

    private

      def resolve_with_error_wrapping
        @resolver.resolve(demands, @molinillo_graph)
      rescue Molinillo::VersionConflict, Molinillo::CircularDependencyError => e
        raise Solve::Errors::NoSolutionError.new(e.message)
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
