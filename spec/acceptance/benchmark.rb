require 'benchmark'
require 'solve'
require File.expand_path("../large_graph_no_solution", __FILE__)
require File.expand_path("../opscode_ci_graph", __FILE__)

PROBLEM = OpscodeCiGraph
N = 1

def demands
  PROBLEM::DEMANDS
end

def artifacts
  PROBLEM::ARTIFACTS
end

require 'pp'

def create_graph
  graph = Solve::Graph.new
  artifacts.each do |name, all_artifact_versions|
    all_artifact_versions.each do |artifact|
      graph.artifact(name, artifact[:version])
      artifact[:dependencies].each do |dep|
        dep_name, dep_constraint = dep
        graph.artifact(name, artifact[:version])
          .depends(dep_name, dep_constraint)
      end
    end
  end

  graph
end

STATIC_GRAPH = create_graph

def solve_gecode
  Solve::Solver.new(STATIC_GRAPH, demands, {}).resolve({})
rescue Solve::Errors::NoSolutionError
end

Benchmark.bm(12) do |x|
  x.report("Create graph")   { N.times { create_graph } }
  x.report("Solve Gecode") { N.times { solve_gecode } }
end
