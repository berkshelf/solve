module Solve
  class Artifact
    attr_reader :graph
    attr_reader :name
    attr_reader :version

    # @param [Solve::Graph] graph
    # @param [#to_s] name
    # @param [Solve::Version, #to_s] version
    def initialize(graph, name, version)
      @graph = graph
      @name = name
      @version = Version.new(version)
      @dependencies = Hash.new
    end

    # @overload dependencies(name, constraint)
    #   Return the Solve::Dependency from the collection of
    #   dependencies with the given name and constraint.
    #
    #   @param [#to_s]
    #   @param [Solve::Constraint, #to_s]
    #
    #   @return [Solve::Dependency]
    # @overload dependencies
    #   Return the collection of dependencies
    #
    #   @return [Array<Solve::Dependency>]
    def dependencies(*args)
      if args.empty?
        return dependency_collection
      end
      if args.length > 2
        raise ArgumentError, "Unexpected number of arguments. You gave: #{args.length}. Expected: 2 or less."
      end

      name, constraint = args
      constraint ||= ">= 0.0.0"

      if name.nil?
        raise ArgumentError, "A name must be specified. You gave: #{args}."
      end

      dependency = Dependency.new(self, name, constraint)
      add_dependency(dependency)
    end
    alias_method :depends, :dependencies

    # Add a Solve::Dependency to the collection of dependencies 
    # and return the added Solve::Dependency. No change will be
    # made if the dependency is already a member of the collection.
    #
    # @param [Solve::Dependency] dependency
    #
    # @return [Solve::Dependency]
    def add_dependency(dependency)
      unless has_dependency?(dependency)
        dep_graph = graph.send(:dep_graph)
        a = dep_graph.package(self.name).add_version(DepSelector::Version.new(self.version.to_s))
        dep_pack = dep_graph.package(dependency.name)
        a.dependencies << DepSelector::Dependency.new(dep_pack, DepSelector::VersionConstraint.new(dependency.constraint.to_s))
        @dependencies[dependency.to_s] = dependency
      end

      dependency
    end

    # @param [Solve::Dependency] dependency
    #
    # @return [Solve::Dependency, nil]
    def remove_dependency(dependency)
      if has_dependency?(dependency)
        @dependencies.delete(dependency.to_s)
      end
    end

    # @param [Solve::Dependency] dependency
    #
    # @return [Boolean]
    def has_dependency?(dependency)
      @dependencies.has_key?(dependency.to_s)
    end

    # @return [Solve::Artifact, nil]
    def delete
      unless graph.nil?
        result = graph.remove_artifact(self)
        @graph = nil
        result
      end
    end

    def to_s
      "#{name}-#{version}"
    end

    private

      # @return [Array<Solve::Dependency>]
      def dependency_collection
        @dependencies.collect { |name, dependency| dependency }
      end
  end
end
