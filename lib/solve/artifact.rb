module Solve
  class Artifact
    attr_reader :graph
    attr_reader :name
    attr_reader :version

    # @param [#to_s] name
    # @param [#to_s] version
    def initialize(graph, name, version)
      @graph = graph
      @name = name
      @version = Version.new(version)
      @dependencies = Array.new
    end

    # @overload dependencies(name, constraint)
    #   @param [#to_s]
    #   @param [#to_s]
    #
    #   @return [Solve::Dependency]
    # @overload dependencies()
    #   @return [Array<Solve::Dependency>]
    def dependencies(*args)

    end

    # @param [#to_s] name
    # @param [#to_s] constraint
    #
    # @return [Array<Solve::Dependency>]
    def depends(name, constraint)
      dependency = Dependency.new(self, constraint)

      unless @dependencies.include?(dependency)
        @dependencies << dependency
      end

      @dependencies
    end

    # @return [Solve::Artifact]
    def delete
      @graph = nil
    end

    def to_s
      "#{name}-#{version}"
    end
  end
end
