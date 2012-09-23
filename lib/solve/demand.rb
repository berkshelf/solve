module Solve
  # @author Jamie Winsor <jamie@vialstudios.com>
  class Demand
    attr_reader :solver
    attr_reader :name
    attr_reader :constraint

    # @param [Solve::Solver] solver
    # @param [#to_s] name
    # @param [Solve::Constraint, #to_s] constraint
    def initialize(solver, name, constraint = ">= 0.0.0")
      @solver = solver
      @name = name
      @constraint = if constraint.is_a?(Solve::Constraint)
        constraint
      else
        Constraint.new(constraint.to_s)
      end
    end

    # @return [Solve::Demand, nil]
    def delete
      unless solver.nil?
        result = solver.remove_demand(self)
        @solver = nil
        result
      end
    end

    def to_s
      "#{name} (#{constraint})"
    end
  end
end
