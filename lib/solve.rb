require 'forwardable'
require 'json'
require 'solve/errors'

# @author Jamie Winsor <reset@riotgames.com>
module Solve
  autoload :Version, 'solve/version'
  autoload :Artifact, 'solve/artifact'
  autoload :Constraint, 'solve/constraint'
  autoload :Dependency, 'solve/dependency'
  autoload :Graph, 'solve/graph'
  autoload :Demand, 'solve/demand'
  autoload :Solver, 'solve/solver'

  class << self
    # A quick solve. Given the "world" as we know it (the graph) and a list of
    # requirements (demands) which must be met. Return me the best solution of
    # artifacts and verisons that I should use.
    #
    # If a ui object is passed in, the resolution will be traced
    #
    # @param [Solve::Graph] graph
    # @param [Array<Solve::Demand>, Array<String, String>] demands
    # @param [#say, nil] ui (nil)
    #
    # @raise [NoSolutionError]
    #
    # @return [Hash]
    def it!(graph, demands, ui = nil)
      Solver.new(graph, demands, ui).resolve
    end
  end
end
