require 'json'

module Solve
  class Solver
    class Serializer
      # @param [Solve::Solver] solver
      #
      # @return [String]
      def serialize(solver)
        graph = solver.graph
        demands = solver.demands

        graph_hash = format_graph(graph)
        demands_hash = format_demands(demands)

        problem = graph_hash.merge(demands_hash)
        problem.to_json
      end

      # @param [Hash, #to_s] solver a json string or a hash representing a solver
      #
      # @return [Solve::Solver]
      def deserialize(solver)
        unless solver.is_a?(Hash)
          solver = JSON.parse(solver.to_s)
        end

        graph_spec = solver["graph"]
        demands_spec = solver["demands"]

        graph = load_graph(graph_spec)
        demands = load_demands(demands_spec)

        Solve::Solver.new(graph, demands)
      end

      private

        def format_graph(graph)
          artifacts = graph.artifacts.inject([]) do |list, artifact|
            list << format_artifact(artifact)
          end
          { "graph" => artifacts }
        end

        def format_artifact(artifact)
          dependencies = artifact.dependencies.inject([]) do |list, dependency|
            list << format_dependency(dependency)
          end

          {
            "name" => artifact.name,
            "version" => artifact.version.to_s,
            "dependencies" => dependencies
          }
        end

        def format_dependency(dependency)
          {
            "name" => dependency.name,
            "constraint" => dependency.constraint.to_s
          }
        end

        def format_demands(demands)
          demands_list = demands.inject([]) do |list, demand|
            list << format_demand(demand)
          end
          { "demands" => demands_list }
        end

        def format_demand(demand)
          {
            "name" => demand.name,
            "constraint" => demand.constraint.to_s
          }
        end

        def load_graph(artifacts_list)
          graph = Solve::Graph.new
          artifacts_list.each do |artifact_spec|
            load_artifact(graph, artifact_spec)
          end
          graph
        end

        def load_artifact(graph, artifact_spec)
          artifact = graph.artifacts(artifact_spec["name"], artifact_spec["version"])
          artifact_spec["dependencies"].each do |dependency_spec|
            load_dependency(artifact, dependency_spec)
          end
          artifact
        end

        def load_dependency(artifact, dependency_spec)
          artifact.depends(dependency_spec["name"], dependency_spec["constraint"])
        end

        def load_demands(demand_specs)
          demand_specs.inject([]) do |list, demand_spec|
            list << [demand_spec["name"], demand_spec["constraint"]]
          end
        end
    end
  end
end
