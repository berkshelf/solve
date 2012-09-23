module Solve
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Solver
    attr_reader :graph

    def initialize(graph, demands = Array.new)
      @graph = graph
      @demands = Hash.new

      Array(demands).each do |l_demand|
        demands(l_demand)
      end
    end

    # @return [Hash]
    def resolve
      Hash.new
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
        @demands[demand.key] = demand
      end

      demand
    end
    alias_method :demand, :add_demand

    # @param [Solve::Demand, nil] demand
    def remove_demand(demand)
      if has_demand?(demand)
        @demands.delete(demand.key)
      end
    end

    # @param [Solve::Demand] demand
    #
    # @return [Boolean]
    def has_demand?(demand)
      @demands.has_key?(demand.key)
    end

    private

      # @return [Array<Solve::Demand>]
      def demand_collection
        @demands.collect { |name, demand| demand }
      end
  end
end
