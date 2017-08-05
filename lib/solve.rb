require "semverse"

module Solve
  require_relative "solve/artifact"
  require_relative "solve/demand"
  require_relative "solve/dependency"
  require_relative "solve/version"
  require_relative "solve/errors"
  require_relative "solve/graph"
  require_relative "solve/ruby_solver"
  require_relative "solve/gecode_solver"

  # We have to set the default engine here, it gets set on the wrong object if
  # we put this in the metaclass context below.
  @engine = :ruby

  class << self
    # @return [Solve::Formatter]
    attr_reader :tracer

    # Returns the currently configured engine.
    # @see #engine=
    # @return [Symbol]
    attr_reader :engine

    # Sets the solving backend engine. Solve supports 2 engines:
    # * `:ruby` - Molinillo, a pure ruby solver
    # * `:gecode` - dep-selector, a wrapper around the Gecode CSP solver library
    #
    # Note that dep-selector is an optional dependency and may therefore not be
    # available.
    #
    # @param [Symbol] selected_engine
    # @return [Symbol] selected_engine
    # @raise [Solve::Errors::EngineNotAvailable] when the selected engine's deps aren't installed.
    # @raise [Solve::Errors::InvalidEngine] when `selected_engine` is invalid.
    def engine=(selected_engine)
      engine_class = solver_for_engine(selected_engine)
      if engine_class.nil?
        raise Errors::InvalidEngine, "Engine `#{selected_engine}` is not supported. Valid values are `:ruby`, `:gecode`"
      else
        engine_class.activate
      end
      @engine = selected_engine
    end

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
      solver_for_engine(engine).new(graph, demands, options).resolve(options)
    end

    def solver_for_engine(engine_name)
      case engine_name
      when :ruby
        RubySolver
      when :gecode
        GecodeSolver
      end
    end

    private :solver_for_engine
  end

end
