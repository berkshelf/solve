require "spec_helper"
require "solve/ruby_solver"

describe Solve::Solver::Serializer do

  let(:graph) do
    Solve::Graph.new.tap do |g|
      g.artifact("A", "1.0.0").depends("B", "1.0.0")
      g.artifact("B", "1.0.0").depends("C", "1.0.0")
      g.artifact("C", "1.0.0")
    end
  end

  let(:demands) { [["A", "1.0.0"]] }

  let(:serializer) { Solve::Solver::Serializer.new }

  it "deserializes a serialized problem to an equivalent problem" do
    problem = Solve::Problem.new(graph, demands)
    serialized = serializer.serialize(problem)
    deserialized = serializer.deserialize(serialized)

    problem.graph.should eql(deserialized.graph)
    problem.demands.should eql(deserialized.demands)
  end

  it "creates a problem from a solver" do
    solver = Solve::RubySolver.new(graph, demands)
    problem = Solve::Problem.from_solver(solver)
    expect(problem.demands).to eq([["A", "= 1.0.0"]])
    expect(problem.graph).to eq(graph)
  end
end
