require 'spec_helper'

describe Solve::GecodeSolver do
  let(:graph) { double(Solve::Graph) }
  let(:demands) { [["mysql"], ["nginx"]] }
  subject(:solver) { described_class.new(graph, demands) }

  it "has a list of demands as ruby literals" do
    expect(solver.demands_array).to eq(demands)
  end

  it "has a list of demands as model objects" do
    expected = [
      Solve::Demand.new(solver, "mysql"),
      Solve::Demand.new(solver, "nginx"),
    ]
    expect(solver.demands).to eq(expected)
  end

  it "has a graph" do
    expect(solver.graph).to eq(graph)
  end

  describe "when the constraints are solvable" do
    let(:graph) do
      graph = Solve::Graph.new
      graph.artifact("A", "1.0.0")
      graph.artifact("B", "1.0.0")
        .depends("A")
      graph
    end

    let(:demands) { [["A"], ["B"]] }

    it "gives the solution as a Hash" do
      expect(solver.resolve).to eq("A" => "1.0.0", "B" => "1.0.0")
    end

    it "gives the solution in sorted form" do
      expect(solver.resolve(sorted: true)).to eq([["A", "1.0.0"], ["B", "1.0.0"]])
    end
  end

  describe "when the constraints are not solvable" do
    let(:error) do
      begin
        solver.resolve
      rescue => e
        e
      else
        raise "Expected resolve to cause an error"
      end
    end

    context "and dep-selector identifies missing artifacts" do
      let(:graph) do
        graph = Solve::Graph.new
        graph.artifact("A", "1.0.0")
        graph
      end

      let(:demands) { [ ["Z"] ] }

      it "raises an error detailing the missing artifacts" do
        expect(error.to_s).to include("Missing artifacts: Z")
      end
    end

    context "and dep-selector identifies constraints that exclude all known versions" do
      let(:graph) do
        graph = Solve::Graph.new
        graph.artifact("A", "1.0.0")
        graph
      end

      let(:demands) { [ ["A", "> 1.0.0"] ] }

      it "raises an error detailing the missing artifacts" do
        expect(error.to_s).to include("Required artifacts do not exist at the desired version")
        expect(error.to_s).to include("Constraints that match no available version: (A > 1.0.0)")
      end
    end

    context "and dep-selector identifies dependency conflicts" do
      let(:graph) do
        graph = Solve::Graph.new
        graph.artifact("A", "1.0.0")
          .depends("B")
          .depends("C")
        graph.artifact("B", "1.0.0")
          .depends("D", "= 1.0.0")
        graph.artifact("C", "1.0.0")
          .depends("D", "= 2.0.0")
        graph.artifact("D", "1.0.0")
        graph.artifact("D", "2.0.0")
        graph
      end

      let(:demands) { [ [ "A" ] ] }

      it "raises an error detailing the missing artifacts" do
        expect(error.to_s).to include("Demand that cannot be met: (A >= 0.0.0)")
        expect(error.to_s).to include("Artifacts for which there are conflicting dependencies: D = 1.0.0 -> []")
      end
    end

    context "and dep-selector times out looking for a solution" do
      let(:selector) { double(DepSelector::Selector) }

      before do
        graph.stub(:artifacts).and_return([])
        DepSelector::Selector.stub(:new).and_return(selector)
        selector.stub(:find_solution).and_raise(DepSelector::Exceptions::TimeBoundExceeded)
      end

      it "raises an error explaining no solution could be found" do
        expect(error.to_s).to include("The dependency constraints could not be solved in the time allotted.")
      end
    end

    context "and dep-selector times out looking for dependency conflicts" do
      let(:selector) { double(DepSelector::Selector) }

      before do
        graph.stub(:artifacts).and_return([])
        DepSelector::Selector.stub(:new).and_return(selector)
        selector.stub(:find_solution).and_raise(DepSelector::Exceptions::TimeBoundExceededNoSolution)
      end

      it "raises a NoSolutionCauseUnknown error to indicate that no debug info was generated" do
        expect(error).to be_a_kind_of(Solve::Errors::NoSolutionCauseUnknown)
      end

      it "raises an error explaining that no solution exists but the cause could not be determined" do
        expect(error.to_s).to include("There is a dependency conflict, but the solver could not determine the precise cause in the time allotted.")
      end
    end
  end

  describe "finding unsatisfiable demands" do
    it "partitions demands into satisfiable and not satisfiable"
  end

  describe "supporting Serializer interface" do
    let(:serializer) { Solve::Solver::Serializer.new }

    before { graph.stub(:artifacts).and_return([]) }

    it "implements the required interface" do
      json_string = serializer.serialize(solver)
      problem_data = JSON.parse(json_string)
      expected_demands = [
        {"name" => "mysql", "constraint" => ">= 0.0.0"},
        {"name" => "nginx", "constraint" => ">= 0.0.0"}
      ]

      expect(problem_data["demands"]).to eq(expected_demands)
    end
  end
end

