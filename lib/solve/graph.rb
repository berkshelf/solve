module Solve
  class Graph
    class << self
      # Create a key for a graph from an instance of an Artifact or Dependency
      #
      # @param [Solve::Artifact, Solve::Dependency] object
      #
      # @raise [ArgumentError] if an instance of an object of an unknown type is given
      #
      # @return [Symbol]
      def key_for(object)
        case object
        when Solve::Artifact
          artifact_key(object.name, object.version)
        when Solve::Dependency
          dependency_key(object.name, object.constraint)
        else
          raise ArgumentError, "Could not generate graph key for Class: #{object.class}"
        end
      end

      # Create a key representing an artifact for an instance of Graph
      #
      # @param [#to_s] name
      # @param [#to_s] version
      #
      # @return [Symbol]
      def artifact_key(name, version)
        "#{name}-#{version}".to_sym
      end

      # Create a key representing an dependency for an instance of Graph
      #
      # @param [#to_s] name
      # @param [#to_s] constraint
      #
      # @return [Symbol]
      def dependency_key(name, constraint)
        "#{name}-#{constraint}".to_sym
      end
    end

    def initialize
      @artifacts = Hash.new
    end

    # @overload artifacts(name, version)
    #   Return the Solve::Artifact from the collection of artifacts
    #   with the given name and version.
    #
    #   @param [#to_s]
    #   @param [Solve::Version, #to_s]
    #
    #   @return [Solve::Artifact]
    # @overload artifacts
    #   Return the collection of artifacts
    #
    #   @return [Array<Solve::Artifact>]
    def artifacts(*args)
      if args.empty?
        return artifact_collection
      end
      unless args.length == 2
        raise ArgumentError, "Unexpected number of arguments. You gave: #{args.length}. Expected: 0 or 2."
      end

      name, version = args

      if name.nil? || version.nil?
        raise ArgumentError, "A name and version must be specified. You gave: #{args}."
      end

      artifact = Artifact.new(self, name, version)
      add_artifact(artifact)
    end

    # Return all the artifacts from the collection of artifacts
    # with the given name.
    #
    # @param [String] name
    #
    # @return [Array<Solve::Artifact>]
    def versions(name, constraint = ">= 0.0.0")
      constraint = constraint.is_a?(Constraint) ? constraint : Constraint.new(constraint)

      artifacts.select do |art|
        art.name == name && constraint.satisfies?(art.version)
      end
    end

    # Add a Solve::Artifact to the collection of artifacts and
    # return the added Solve::Artifact. No change will be made
    # if the artifact is already a member of the collection.
    #
    # @param [Solve::Artifact] artifact
    #
    # @return [Solve::Artifact]
    def add_artifact(artifact)
      unless has_artifact?(artifact.name, artifact.version)
        @artifacts[self.class.key_for(artifact)] = artifact
      end

      get_artifact(artifact.name, artifact.version)
    end

    # Retrieve the artifact from the graph with the matching name and version
    #
    # @param [String] name
    # @param [Solve::Version, #to_s] version
    #
    # @return [Solve::Artifact, nil]
    def get_artifact(name, version)
      @artifacts.fetch(self.class.artifact_key(name, version.to_s), nil)
    end

    # Remove the given instance of artifact from the graph
    #
    # @param [Solve::Artifact, nil] artifact
    def remove_artifact(artifact)
      if has_artifact?(artifact.name, artifact.version)
        @artifacts.delete(self.class.key_for(artifact))
      end
    end

    # Check if an artifact with a matching name and version is a member of this instance
    # of graph
    #
    # @param [String] name
    # @param [Solve::Version, #to_s] version
    #
    # @return [Boolean]
    def has_artifact?(name, version)
      !get_artifact(name, version).nil?
    end

    # @param [Object] other
    #
    # @return [Boolean]
    def ==(other)
      return false unless other.is_a?(self.class)

      self_artifacts = self.artifacts
      other_artifacts = other.artifacts

      self_dependencies = self_artifacts.inject([]) do |list, artifact|
        list << artifact.dependencies
      end.flatten

      other_dependencies = other_artifacts.inject([]) do |list, artifact|
        list << artifact.dependencies
      end.flatten

      self_artifacts.size == other_artifacts.size &&
        self_dependencies.size == other_dependencies.size &&
        self_artifacts.all? { |artifact| other_artifacts.include?(artifact) } &&
        self_dependencies.all? { |dependency| other_dependencies.include?(dependency) }
    end
    alias_method :eql?, :==

    private

      # @return [Array<Solve::Artifact>]
      def artifact_collection
        @artifacts.collect { |name, artifact| artifact }
      end
  end
end
