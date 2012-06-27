require 'solve/errors'

module Solve
  autoload :Version, 'solve/version'
  autoload :Artifact, 'solve/artifact'
  autoload :Constraint, 'solve/constraint'
  autoload :Dependency, 'solve/dependency'
  autoload :Graph, 'solve/graph'
  autoload :Demand, 'solve/demand'

  class << self
    # @param [Solve::Graph] graph
    #
    # @return [Hash]
    def it(graph)
      it!(graph)
    rescue NoSolutionError
      nil
    end

    # @param [Solve::Graph] graph
    #
    # @return [Hash]
    def it!(graph)
      raise NoSolutionError
    end
  end
end
