module Solve
  class Demand
    # A reference to the solver this demand belongs to
    #
    # @return [Solve::Solver]
    attr_reader :solver

    # The name of the artifact this demand is for
    #
    # @return [String]
    attr_reader :name

    # The acceptable constraint of the artifact this demand is for
    #
    # @return [Solve::Constraint]
    attr_reader :constraint

    # @param [Solve::Solver] solver
    # @param [#to_s] name
    # @param [Solve::Constraint, #to_s] constraint
    def initialize(solver, name, constraint = DEFAULT_CONSTRAINT)
      @solver     = solver
      @name       = name
      @constraint = Constraint.coerce(constraint)
    end

    def to_s
      "#{name} (#{constraint})"
    end

    def ==(other)
      other.is_a?(self.class) &&
        self.name == other.name &&
        self.constraint == other.constraint
    end
    alias_method :eql?, :==
  end
end
