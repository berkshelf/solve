module Solve
  class Demand
    attr_reader :graph
    attr_reader :name
    attr_reader :constraint

    def initialize(graph, name, constraint)
      @graph = graph
      @name = name
      @constraint = Constraint.new(constraint)
    end

    def to_s
      "#{name} (#{constraint})"
    end
  end
end
