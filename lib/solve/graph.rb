module Solve
  class Graph
    def initialize
      @artifacts = {}
      @artifacts_by_name = Hash.new { |hash, key| hash[key] = [] }
    end

    # Check if an artifact with a matching name and version is a member of this instance
    # of graph
    #
    # @param [String] name
    # @param [Semverse::Version, #to_s] version
    #
    # @return [Boolean]
    def artifact?(name, version)
      !find(name, version).nil?
    end
    alias_method :has_artifact?, :artifact?

    def find(name, version)
      @artifacts["#{name}-#{version}"]
    end

    # Add an artifact to the graph
    #
    # @param [String] name
    # @Param [String] version
    def artifact(name, version)
      unless artifact?(name, version)
        artifact = Artifact.new(self, name, version)
        @artifacts["#{name}-#{version}"] = artifact
        @artifacts_by_name[name] << artifact
      end

      @artifacts["#{name}-#{version}"]
    end

    # Return the collection of artifacts
    #
    # @return [Array<Solve::Artifact>]
    def artifacts
      @artifacts.values
    end

    # Return all the artifacts from the collection of artifacts
    # with the given name.
    #
    # @param [String] name
    #
    # @return [Array<Solve::Artifact>]
    def versions(name, constraint = Semverse::DEFAULT_CONSTRAINT)
      constraint = Semverse::Constraint.coerce(constraint)

      if constraint == Semverse::DEFAULT_CONSTRAINT
        @artifacts_by_name[name]
      else
        @artifacts_by_name[name].select do |artifact|
          constraint.satisfies?(artifact.version)
        end
      end
    end

    # @param [Object] other
    #
    # @return [Boolean]
    def ==(other)
      return false unless other.is_a?(Graph)
      return false unless artifacts.size == other.artifacts.size

      self_artifacts = self.artifacts
      other_artifacts = other.artifacts

      self_dependencies = self_artifacts.inject([]) do |list, artifact|
        list << artifact.dependencies
      end.flatten

      other_dependencies = other_artifacts.inject([]) do |list, artifact|
        list << artifact.dependencies
      end.flatten

      self_dependencies.size == other_dependencies.size &&
      self_artifacts.all? { |artifact| other_artifacts.include?(artifact) } &&
      self_dependencies.all? { |dependency| other_dependencies.include?(dependency) }
    end
    alias_method :eql?, :==
  end
end
