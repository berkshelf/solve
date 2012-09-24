module Solve
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Solver
    class << self
      # Create a key to identify a demand on a Solver.
      #
      # @param [Solve::Demand] demand
      #
      # @raise [NoSolutionError]
      #
      # @return [Symbol]
      def demand_key(demand)
        "#{demand.name}-#{demand.constraint}".to_sym
      end

      # Returns all of the versions which satisfy all of the given constraints
      #
      # @param [Array<Solve::Constraint>, Array<String>] constraints
      # @param [Array<Solve::Version>, Array<String>] versions
      #
      # @return [Array<Solve::Version>]
      def satisfy_all(constraints, versions)
        constraints = Array(constraints).collect do |con|
          con.is_a?(Constraint) ? con : Constraint.new(con)
        end.uniq

        versions = Array(versions).collect do |ver|
          ver.is_a?(Version) ? ver : Version.new(ver)
        end.uniq

        versions.select do |ver|
          constraints.all? { |constraint| constraint.satisfies?(ver) }
        end
      end

      # Return the best version from the given list of versions for the given list of constraints
      #
      # @param [Array<Solve::Constraint>, Array<String>] constraints
      # @param [Array<Solve::Version>, Array<String>] versions
      #
      # @raise [NoSolutionError] if version matches the given constraints
      #
      # @return [Solve::Version]
      def satisfy_best(constraints, versions)
        solution = satisfy_all(constraints, versions)

        if solution.empty?
          raise Errors::NoSolutionError
        end

        solution.sort.last
      end
    end

    # The world as we know it
    #
    # @return [Solve::Graph]
    attr_reader :graph

    # @param [Solve::Graph] graph
    # @param [Array<String>, Array<Array<String, String>>] demands
    def initialize(graph, demands = Array.new)
      @graph = graph
      @demands = Hash.new

      Array(demands).each do |l_demand|
        demands(*l_demand)
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
        @demands[self.class.demand_key(demand)] = demand
      end

      demand
    end
    alias_method :demand, :add_demand

    # @param [Solve::Demand, nil] demand
    def remove_demand(demand)
      if has_demand?(demand)
        @demands.delete(self.class.demand_key(demand))
      end
    end

    # @param [Solve::Demand] demand
    #
    # @return [Boolean]
    def has_demand?(demand)
      @demands.has_key?(self.class.demand_key(demand))
    end

    private

      # @return [Array<Solve::Demand>]
      def demand_collection
        @demands.collect { |name, demand| demand }
      end
  end
end
