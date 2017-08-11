require "set"
require "molinillo"
require "molinillo/modules/specification_provider"
require_relative "solver/serializer"

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

      # For optional solver engines, this attempts to load depenencies. The
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
      @dependency_source = options[:dependency_source] || "user-specified dependency"

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

      solution = solved_graph.map(&:payload)

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
      @ui.say("Starting dependency resolution") if @ui
    end

    # Callback required by Molinillo, called when the solve is complete.
    # @return nil
    def after_resolution
      @ui.say("Finished dependency resolution") if @ui
    end

    # Callback required by Molinillo, called when resolving every progress_rate
    # @return nil
    def indicate_progress
      nil
    end

    # Callback required by Molinillo, gives debug information about the solution
    # @return nil
    def debug(current_resolver_depth = 0)
      # debug info will be returned if you call yield here, but it seems to be
      # broken in current Molinillo
      @ui.say(yield) if @ui
    end

    include Molinillo::SpecificationProvider

    # Callback required by Molinillo
    # Search for the specifications that match the given dependency.
    # The specifications in the returned array will be considered in reverse
    # order, so the latest version ought to be last.
    # @note This method should be 'pure', i.e. the return value should depend
    #   only on the `dependency` parameter.
    #
    # @param [Object] dependency
    # @return [Array<Solve::Artifact>] the artifacts that match the dependency.
    def search_for(dependency)
      # This array gets mutated by Molinillo; it's okay because sort returns a
      # new array.
      graph.versions(dependency.name, dependency.constraint).sort
    end

    # Callback required by Molinillo
    # Returns the dependencies of `specification`.
    # @note This method should be 'pure', i.e. the return value should depend
    #   only on the `specification` parameter.
    #
    # @param [Object] specification
    # @return [Array<Solve::Dependency>] the dependencies of the given artifact
    def dependencies_for(specification)
      specification.dependencies
    end

    # Callback required by Molinillo
    # Determines whether the given `requirement` is satisfied by the given
    # `spec`, in the context of the current `activated` dependency graph.
    #
    # @param [Object] requirement
    # @param [DependencyGraph] activated the current dependency graph in the
    #   resolution process.
    # @param [Object] spec
    # @return [Boolean] whether `requirement` is satisfied by `spec` in the
    #   context of the current `activated` dependency graph.
    def requirement_satisfied_by?(requirement, activated, spec)
      version = spec.version
      return false unless requirement.constraint.satisfies?(version)
      shared_possibility_versions = possibility_versions(requirement, activated)
      return false if !shared_possibility_versions.empty? && !shared_possibility_versions.include?(version)
      true
    end

    # Searches the current dependency graph to find previously activated
    # requirements for the current artifact.
    #
    # @param [Object] requirement
    # @param [DependencyGraph] activated the current dependency graph in the
    #   resolution process.
    # @return [Array<Semverse::Version> the list of currently activated versions
    # of this requirement
    def possibility_versions(requirement, activated)
      activated.vertices.values.flat_map do |vertex|

        next unless vertex.payload

        next unless vertex.name == requirement.name

        if vertex.payload.respond_to?(:possibilities)
          vertex.payload.possibilities.map(&:version)
        else
          vertex.payload.version
        end
      end.compact
    end
    private :possibility_versions

    # Callback required by Molinillo
    # Returns the name for the given `dependency`.
    # @note This method should be 'pure', i.e. the return value should depend
    #   only on the `dependency` parameter.
    #
    # @param [Object] dependency
    # @return [String] the name for the given `dependency`.
    def name_for(dependency)
      dependency.name
    end

    # Callback required by Molinillo
    # @return [String] the name of the source of explicit dependencies, i.e.
    #   those passed to {Resolver#resolve} directly.
    def name_for_explicit_dependency_source
      @dependency_source
    end

    # Callback required by Molinillo
    # Sort dependencies so that the ones that are easiest to resolve are first.
    # Easiest to resolve is (usually) defined by:
    #   1) Is this dependency already activated?
    #   2) How relaxed are the requirements?
    #   3) Are there any conflicts for this dependency?
    #   4) How many possibilities are there to satisfy this dependency?
    #
    # @param [Array<Object>] dependencies
    # @param [DependencyGraph] activated the current dependency graph in the
    #   resolution process.
    # @param [{String => Array<Conflict>}] conflicts
    # @return [Array<Solve::Dependency>] the dependencies sorted by preference.
    def sort_dependencies(dependencies, activated, conflicts)
      dependencies.sort_by do |dependency|
        name = name_for(dependency)
        [
          activated.vertex_named(name).payload ? 0 : 1,
          conflicts[name] ? 0 : 1,
          search_for(dependency).count,
        ]
      end
    end

    # Callback required by Molinillo
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
