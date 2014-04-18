require 'semverse'

module Solve
  require_relative 'solve/artifact'
  require_relative 'solve/demand'
  require_relative 'solve/dependency'
  require_relative 'solve/version'
  require_relative 'solve/errors'
  require_relative 'solve/graph'
  require_relative 'solve/solver'

  class << self
    # @return [Solve::Formatter]
    attr_reader :tracer

    # A quick solve. Given the "world" as we know it (the graph) and a list of
    # requirements (demands) which must be met. Return me the best solution of
    # artifacts and verisons that I should use.
    #
    # If a ui object is passed in, the resolution will be traced
    #
    # @param [Solve::Graph] graph
    # @param [Array<Solve::Demand>, Array<String, String>] demands
    #
    # @option options [Boolean] :sorted (false)
    #   should the output be a sorted list rather than a Hash
    #
    # @raise [NoSolutionError]
    #
    # @return [Hash]
    def it!(graph, demands, options = {})
      Solver.new(graph, demands).resolve(options)
    end
  end
end
