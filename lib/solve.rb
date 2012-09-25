require 'forwardable'
require 'json'
require 'solve/errors'

# @author Jamie Winsor <jamie@vialstudios.com>
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
    # @param [Solve::Graph] graph
    # @param [Array<Solve::Demand>, Array<String, String>] demands
    #
    # @raise [NoSolutionError]
    #
    # @return [Hash]
    def it!(graph, demands)
      Solver.new(graph, demands).resolve
    end
  end
end
