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
    # @return [Semverse::Constraint]
    attr_reader :constraint

    # @param [Solve::Artifact] artifact
    # @param [#to_s] name
    # @param [Semverse::Constraint, #to_s] constraint
    def initialize(artifact, name, constraint = Semverse::DEFAULT_CONSTRAINT)
      @artifact   = artifact
      @name       = name
      @constraint = Semverse::Constraint.coerce(constraint)
    end

    def to_s
      "#{name} (#{constraint})"
    end
    alias :inspect :to_s

    # @param [Object] other
    #
    # @return [Boolean]
    def ==(other)
      other.is_a?(self.class) &&
        name == other.name &&
        artifact == other.artifact &&
        constraint == other.constraint
    end
    alias_method :eql?, :==
  end
end
