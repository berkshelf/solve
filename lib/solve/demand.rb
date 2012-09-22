module Solve
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Demand
    attr_reader :graph
    attr_reader :name
    attr_reader :constraint

    # @param [Solve::Graph] graph
    # @param [#to_s] name
    # @param [Solve::Constraint, #to_s] constraint
    def initialize(graph, name, constraint = nil)
      @graph = graph
      @name = name

      if constraint
        @constraint = if constraint.is_a?(Solve::Constraint)
          constraint
        else
          Constraint.new(constraint.to_s)
        end
      end
    end

    # @return [Solve::Demand, nil]
    def delete
      unless graph.nil?
        result = graph.remove_demand(self)
        @graph = nil
        result
      end
    end

    def to_s
      s = "#{name}"
      s << "(#{constraint})" if constraint
      s
    end
  end
end
