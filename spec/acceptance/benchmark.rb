require "benchmark"
require "solve"
require "solve/gecode_solver"
require File.expand_path("../large_graph_no_solution", __FILE__)
require File.expand_path("../opscode_ci_graph", __FILE__)

PROBLEM = OpscodeCiGraph
#PROBLEM = LargeGraphNoSolution
N = 100

def demands
  PROBLEM::DEMANDS
end

def artifacts
  PROBLEM::ARTIFACTS
end

require "pp"

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
  Solve::GecodeSolver.new(STATIC_GRAPH, demands).resolve({})
rescue Solve::Errors::NoSolutionError => e
  # Uncomment to look at the error messages. Probably only useful if N == 1
  #puts e
  e
end

def solve_ruby
  Solve::RubySolver.new(STATIC_GRAPH, demands).resolve({})
rescue Solve::Errors::NoSolutionError => e
  # Uncomment to look at the error messages. Probably only useful if N == 1
  #puts e
  e
end

Benchmark.bm(12) do |x|
  x.report("Create graph")   { N.times { create_graph } }
  x.report("Solve Gecode") { N.times { solve_gecode } }
  x.report("Solve Ruby") { N.times { solve_ruby } }
end
