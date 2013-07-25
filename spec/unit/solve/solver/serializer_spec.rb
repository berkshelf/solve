require 'spec_helper'

describe Solve::Solver::Serializer do
  it "deserializes a serialized solver to an equivalent solver" do

    graph = Solve::Graph.new

    graph.artifacts("A", "1.0.0").depends("B", "1.0.0")
    graph.artifacts("B", "1.0.0").depends("C", "1.0.0")
    graph.artifacts("C", "1.0.0")

    demands = [["A", "1.0.0"]]

    solver = Solve::Solver.new(graph, demands)
    serializer = Solve::Solver::Serializer.new
    serialized = serializer.serialize(solver)
    deserialized = serializer.deserialize(serialized)

    solver.graph.should eql(deserialized.graph)
    solver.demands.should eql(deserialized.demands)

    result = solver.resolve
    deserialized_result = deserialized.resolve
    result.should eql(deserialized_result)
  end
end
