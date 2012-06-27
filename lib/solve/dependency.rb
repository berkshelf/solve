module Solve
  class Dependency
    attr_reader :artifact
    attr_reader :name
    attr_reader :constraint

    # @param [Solve::Artifact] artifact
    # @param [#to_s] name
    # @param [Solve::Constraint, #to_s] constraint
    def initialize(artifact, name, constraint)
      @artifact = artifact
      @name = name
      @constraint = case constraint
      when Solve::Constraint
        constraint
      else
        Constraint.new(constraint)
      end
    end

    # @return [Solve::Dependency, nil]
    def delete
      unless artifact.nil?
        result = artifact.remove_dependency(self)
        @artifact = nil
        result
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
