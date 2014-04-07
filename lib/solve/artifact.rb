module Solve
  class Artifact
    include Comparable

    # A reference to the graph this artifact belongs to
    #
    # @return [Solve::Graph]
    attr_reader :graph

    # The name of the artifact
    #
    # @return [String]
    attr_reader :name

    # The version of this artifact
    #
    # @return [Semverse::Version]
    attr_reader :version

    # @param [Solve::Graph] graph
    # @param [#to_s] name
    # @param [Semverse::Version, #to_s] version
    def initialize(graph, name, version)
      @graph        = graph
      @name         = name
      @version      = Semverse::Version.new(version)
      @dependencies = {}
    end

    # Check if the artifact has a dependency with the matching name and
    # constraint
    #
    # @param [#to_s] name
    # @param [#to_s] constraint
    #
    # @return [Boolean]
    def dependency?(name, constraint)
      !get_dependency(name, constraint).nil?
    end
    alias_method :has_dependency?, :dependency?

    # Retrieve the dependency from the artifact with the matching name and constraint
    #
    # @param [#to_s] name
    # @param [#to_s] constraint
    #
    # @return [Solve::Artifact, nil]
    def dependency(name, constraint)
      set_dependency(name, constraint)
    end

    # Return the collection of dependencies on this instance of artifact
    #
    # @return [Array<Solve::Dependency>]
    def dependencies
      @dependencies.values
    end

    # Return the Solve::Dependency from the collection of
    # dependencies with the given name and constraint.
    #
    # @param [#to_s] name
    # @param [String] constraint
    #
    # @example Adding dependencies
    #   artifact.depends('nginx')
    #     #=> #<Dependency nginx (>= 0.0.0)>
    #   artifact.depends('ntp', '= 1.0.0')
    #     #=> #<Dependency ntp (= 1.0.0)>
    #
    # @example Chaining dependencies
    #   artifact
    #     .depends('nginx')
    #     .depends('ntp', '~> 1.3')
    #
    # @return [Solve::Artifact]
    def depends(name, constraint = '>= 0.0.0')
      unless dependency?(name, constraint)
        set_dependency(name, constraint)
      end

      self
    end

    def to_s
      "#{name}-#{version}"
    end

    # @param [Object] other
    #
    # @return [Boolean]
    def ==(other)
      other.is_a?(self.class) &&
      self.name == other.name &&
      self.version == other.version
    end
    alias_method :eql?, :==

    # @param [Semverse::Version] other
    #
    # @return [Integer]
    def <=>(other)
      self.version <=> other.version
    end

    private

      def get_dependency(name, constraint)
        @dependencies["#{name}-#{constraint}"]
      end

      def set_dependency(name, constraint)
        @dependencies["#{name}-#{constraint}"] = Dependency.new(self, name, constraint)
      end
  end
end
