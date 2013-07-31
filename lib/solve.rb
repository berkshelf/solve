module Solve
  require_relative 'solve/artifact'
  require_relative 'solve/constraint'
  require_relative 'solve/demand'
  require_relative 'solve/dependency'
  require_relative 'solve/gem_version'
  require_relative 'solve/errors'
  require_relative 'solve/graph'
  require_relative 'solve/solver'
  require_relative 'solve/version'
  require_relative 'solve/tracers'

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
    # @option options [#say] :ui (nil)
    #   a ui object for output, this will be used to output from a Solve::Tracers::HumanReadable if
    #   no other tracer is provided in options[:tracer]
    # @option options [AbstractTracer] :tracer (nil)
    #   a Tracer object that is used to format and output tracing information
    # @option options [Boolean] :sorted (false)
    #   should the output be a sorted list rather than a Hash
    #
    # @raise [NoSolutionError]
    #
    # @return [Hash]
    def it!(graph, demands, options = {})
      @tracer = options[:tracer] || Solve::Tracers.build(options[:ui])
      Solver.new(graph, demands, options[:ui]).resolve(options)
    end
  end
end
