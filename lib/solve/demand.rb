module Solve
  class Demand
    attr_reader :name
    attr_reader :constraint

    def initialize(name, constraint)
      @name = name
      @constraint = Constraint.new(constraint)
    end

    def to_s
      "#{name} (#{constraint})"
    end
  end
end
