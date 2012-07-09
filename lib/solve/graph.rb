module Solve
  class Graph
    def initialize
      @artifacts = Hash.new
      @demands = Hash.new
      @dep_graph = DepSelector::DependencyGraph.new
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

    # Add a Solve::Artifact to the collection of artifacts and
    # return the added Solve::Artifact. No change will be made
    # if the artifact is already a member of the collection.
    #
    # @param [Solve::Artifact] artifact
    #
    # @return [Solve::Artifact]
    def add_artifact(artifact)
      unless has_artifact?(artifact)
        @dep_graph.package(artifact.name).add_version(DepSelector::Version.new(artifact.version.to_s))
        @artifacts[artifact.to_s] = artifact
      end

      artifact
    end

    # @param [Solve::Artifact, nil] artifact
    def remove_artifact(artifact)
      if has_artifact?(artifact)
        @dep_graph.packages.delete(artifact.to_s)
        @artifacts.delete(artifact.to_s)
      end
    end

    # @param [Solve::Artifact] artifact
    #
    # @return [Boolean]
    def has_artifact?(artifact)
      @artifacts.has_key?(artifact.to_s)
    end

    # @overload demands(name, constraint)
    #   Return the Solve::Demand from the collection of demands
    #   with the given name and constraint.
    #
    #   @param [#to_s]
    #   @param [Solve::Constraint, #to_s]
    #
    #   @return [Solve::Demand]
    # @overload demands(name)
    #   Return the Solve::Demand from the collection of demands
    #   with the given name.
    #
    #   @param [#to_s]
    #
    #   @return [Solve::Demand]
    # @overload demands
    #   Return the collection of demands
    #
    #   @return [Array<Solve::Demand>]
    def demands(*args)
      if args.empty?
        return demand_collection
      end
      if args.length > 2
        raise ArgumentError, "Unexpected number of arguments. You gave: #{args.length}. Expected: 2 or less."
      end

      name, constraint = args
      constraint ||= ">= 0.0.0"

      if name.nil?
        raise ArgumentError, "A name must be specified. You gave: #{args}."
      end

      demand = Demand.new(self, name, constraint)
      add_demand(demand)
    end

    # Add a Solve::Demand to the collection of demands and
    # return the added Solve::Demand. No change will be made
    # if the demand is already a member of the collection.
    #
    # @param [Solve::Demand] demand
    #
    # @return [Solve::Demand]
    def add_demand(demand)
      unless has_demand?(demand)
        @demands[demand.to_s] = demand
      end

      demand
    end
    alias_method :demand, :add_demand

    # @param [Solve::Demand, nil] demand
    def remove_demand(demand)
      if has_demand?(demand)
        @demands.delete(demand.to_s)
      end
    end

    # @param [Solve::Demand] demand
    #
    # @return [Boolean]
    def has_demand?(demand)
      @demands.has_key?(demand.to_s)
    end

    private

      attr_reader :dep_graph

      # @return [Array<Solve::Artifact>]
      def artifact_collection
        @artifacts.collect { |name, artifact| artifact }
      end

      # @return [Array<Solve::Demand>]
      def demand_collection
        @demands.collect { |name, demand| demand }
      end
  end
end
