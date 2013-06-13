module Solve
  class Dependency
    # A reference to the artifact this dependency belongs to
    #
    # @return [Solve::Artifact]
    attr_reader :artifact

    # The name of the artifact this dependency represents
    #
    # @return [String]
    attr_reader :name

    # The constraint requirement of this dependency
    #
    # @return [Solve::Constraint]
    attr_reader :constraint

    # @param [Solve::Artifact] artifact
    # @param [#to_s] name
    # @param [Solve::Constraint, #to_s] constraint
    def initialize(artifact, name, constraint = ">= 0.0.0")
      @artifact = artifact
      @name = name
      @constraint = case constraint
      when Solve::Constraint
        constraint
      else
        Constraint.new(constraint)
      end
    end

    # Remove this dependency from the artifact it belongs to
    #
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
