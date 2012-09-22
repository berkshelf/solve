require 'solve/errors'
require 'solve/core_ext'

# @author Jamie Winsor <jamie@vialstudios.com>
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
      true
    end
  end
end
