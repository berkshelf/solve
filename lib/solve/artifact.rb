module Solve
  class Artifact
    include Comparable

    # A reference to the graph this artifact belongs to
    #
    # @return [Solve::Graph]
    attr_reader :graph

    # The name of the artifact
    #
    # @return [String]
    attr_reader :name

    # The version of this artifact
    #
    # @return [Solve::Version]
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

    # Return the Solve::Dependency from the collection of
    # dependencies with the given name and constraint.
    #
    # @param [#to_s] name
    # @param [Solve::Constraint, #to_s] constraint
    #
    # @example adding dependencies
    #   artifact.depends("nginx") => <#Dependency: @name="nginx", @constraint=">= 0.0.0">
    #   artifact.depends("ntp", "= 1.0.0") => <#Dependency: @name="ntp", @constraint="= 1.0.0">
    #
    # @example chaining dependencies
    #   artifact.depends("nginx").depends("ntp")
    #
    # @return [Solve::Artifact]
    def depends(name, constraint = ">= 0.0.0")
      if name.nil?
        raise ArgumentError, "A name must be specified. You gave: #{args}."
      end

      dependency = Dependency.new(self, name, constraint)
      add_dependency(dependency)

      self
    end

    # Return the collection of dependencies on this instance of artifact
    #
    # @return [Array<Solve::Dependency>]
    def dependencies
      @dependencies.collect { |name, dependency| dependency }
    end

    # Retrieve the dependency from the artifact with the matching name and constraint
    #
    # @param [#to_s] name
    # @param [#to_s] constraint
    #
    # @return [Solve::Artifact, nil]
    def get_dependency(name, constraint)
      @dependencies.fetch(Graph.dependency_key(name, constraint), nil)
    end

    # Remove this artifact from the graph it belongs to
    #
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

    # @param [Object] other
    #
    # @return [Boolean]
    def ==(other)
      other.is_a?(self.class) &&
        self.name == other.name &&
        self.version == other.version
    end
    alias_method :eql?, :==

    # @param [Solve::Version] other
    #
    # @return [Integer]
    def <=>(other)
      self.version <=> other.version
    end

    private

      # Add a Solve::Dependency to the collection of dependencies 
      # and return the added Solve::Dependency. No change will be
      # made if the dependency is already a member of the collection.
      #
      # @param [Solve::Dependency] dependency
      #
      # @return [Solve::Dependency]
      def add_dependency(dependency)
        unless has_dependency?(dependency.name, dependency.constraint)
          @dependencies[Graph.key_for(dependency)] = dependency
        end

        get_dependency(dependency.name, dependency.constraint)
      end

      # Remove the matching dependency from the artifact
      #
      # @param [Solve::Dependency] dependency
      #
      # @return [Solve::Dependency, nil]
      def remove_dependency(dependency)
        if has_dependency?(dependency)
          @dependencies.delete(Graph.key_for(dependency))
        end
      end

      # Check if the artifact has a dependency with the matching name and constraint
      #
      # @param [#to_s] name
      # @param [#to_s] constraint
      #
      # @return [Boolean]
      def has_dependency?(name, constraint)
        @dependencies.has_key?(Graph.dependency_key(name, constraint))
      end
  end
end
