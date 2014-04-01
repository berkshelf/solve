require 'tsort'
require_relative 'solver/variable_table'
require_relative 'solver/variable_row'
require_relative 'solver/constraint_table'
require_relative 'solver/constraint_row'
require_relative 'solver/serializer'

module Solve
  class Solver
    def initialize(universe = {})
      @graph = Graph.new
      @universe = Universe.new

      @seen_artifacts = Set.new

      universe.each do |name, info|
        info.each do |version, data|
          key = "#{name}-#{version}"
          artifact = @universe.artifact(name, version)

          data['dependencies'].each do |name, constraint|
            artifact.depends(name, constraint)
          end
        end
      end
    end

    def resolve(demands = {})
      demands.each do |name, constraint|
        versions = versions_for(name, constraint)
        versions.each do |artifact|
          populate(artifact)
        end
      end

      require 'pry'
      binding.pry

      @graph.to_png
    end

    def ac3()

    end

    def populate(artifact)
      if @seen_artifacts.include?(artifact)
        return
      end

      @seen_artifacts.add(artifact)
      @graph.node(artifact)

      artifact.dependencies.each do |dependency|
        possibles = versions_for(dependency.name, dependency.constraint)
        possibles.each do |possible|
          @graph.edge(artifact, possible)
          populate(artifact)
        end
      end
    end

    private

    def versions_for(name, constraint)
      possibles = @universe.versions(name, constraint)

      if possibles.empty?
        raise "Nothing satisifies #{name} (#{constraint})"
      end

      possibles
    end
  end
end
