require 'solve/errors'
require 'solve/core_ext'
require 'dep_selector'

# @author Jamie Winsor <jamie@vialstudios.com>
module Solve
  autoload :Version, 'solve/version'
  autoload :Artifact, 'solve/artifact'
  autoload :Constraint, 'solve/constraint'
  autoload :Dependency, 'solve/dependency'
  autoload :Graph, 'solve/graph'
  autoload :Demand, 'solve/demand'

  class << self
    include DepSelector

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
      dep_graph = graph.send(:dep_graph)
      selector = Selector.new(dep_graph)

      solution_constraints = graph.demands.collect do |demand|
        SolutionConstraint.new(dep_graph.package(demand.name), DepSelector::VersionConstraint.new(demand.constraint.to_s))
      end

      solution = quietly { selector.find_solution(solution_constraints) }

      {}.tap do |artifacts|
        solution.each do |name, constraint|
          artifacts[name] = constraint.to_s
        end
      end
    rescue DepSelector::Exceptions::InvalidSolutionConstraints
      raise Errors::NoSolutionError
    end
  end
end
