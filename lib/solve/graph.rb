module Solve
  class Graph
    def initialize
      @artifacts = Hash.new
    end

    # @param [#to_s] name
    # @param [Solve::Version, #to_s] version
    #
    # @return [Solve::Artifact]
    def artifact(name, version)
      artifact = Artifact.new(self, name, version)
      add_artifact(artifact)
    end

    # @return [Array<Solve::Artifact>]
    def artifacts
      @artifacts.collect { |name, artifact| artifact }
    end

    # Add a Solve::Artifact the collection of artifacts and
    # return the added Solve::Artifact. No change will be made
    # if the artifact is already a member of the collection.
    #
    # @param [Solve::Artifact] artifact
    #
    # @return [Solve::Artifact]
    def add_artifact(artifact)
      unless has_artifact?(artifact)
        @artifacts[artifact.to_s] = artifact
      end

      artifact
    end

    # @param [Solve::Artifact] artifact
    def remove_artifact(artifact)
      if has_artifact?(artifact)
        @artifacts.delete(artifact.to_s)
      end
    end

    # @param [Solve::Artifact] artifact
    def has_artifact?(artifact)
      @artifacts.has_key?(artifact.to_s)
    end

    # @param [#to_s] name
    # @param [Solve::Constraint, #to_s] constraint
    #
    # @return [Solve::Demand]
    def demand(name, constraint)
      demand = Demand.new(name, constraint)
      add_requirement(demand)
    end
  end
end
