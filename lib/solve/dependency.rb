module Solve
  class Dependency
    attr_reader :artifact
    attr_reader :constraint

    # @param [Solve::Artifact] artifact
    # @param [Solve::Constraint, #to_s] constraint
    def initialize(artifact, constraint)
      @artifact = artifact
      @constraint = case constraint
      when Solve::Constraint
        constraint
      else
        Constraint.new(constraint)
      end
    end

    # @param [Object] other
    #
    # @return [Boolean]
    def ==(other)
      other.is_a?(self.class) &&
        self.artifact == other.artifact &&
        self.constraint == other.constraint
    end
    alias_method :eql?, :==
  end
end
