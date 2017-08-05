require "spec_helper"

describe Solve::RubySolver do
  describe "ClassMethods" do
    describe "::timeout" do
      subject { described_class.timeout }

      it "returns 30,000 by default" do
        expect(subject).to eql(30_000)
      end

      context "when the SOLVE_TIMEOUT env variable is set" do
        before { ENV.stub(:[]).with("SOLVE_TIMEOUT") { "30" } }

        it "returns the value multiplied by a thousand" do
          expect(subject).to eql(30_000)
        end
      end
    end

    describe "::activate" do

      it "is a no-op" do
        described_class.activate
      end

    end
  end

  let(:graph) { double(Solve::Graph) }
  let(:demands) { [["mysql"], ["nginx"]] }
  subject(:solver) { described_class.new(graph, demands, dependency_source: "Berksfile") }

  it "has a list of demands as ruby literals" do
    solver.demands_array.should == demands
  end

  it "has a list of demands as model objects" do
    expected = [
      Solve::Demand.new(solver, "mysql"),
      Solve::Demand.new(solver, "nginx"),
    ]
    solver.demands.should == expected
  end

  it "has a graph" do
    solver.graph.should == graph
  end

  describe "when the constraints are solvable" do
    let(:graph) do
      graph = Solve::Graph.new
      graph.artifact("A", "1.0.0")
      graph.artifact("B", "1.0.0").depends("A")
      graph
    end

    let(:demands) { [["A"], ["B"]] }

    it "gives the solution as a Hash" do
      solver.resolve.should == { "A" => "1.0.0", "B" => "1.0.0" }
    end

    it "gives the solution in sorted form" do
      solver.resolve(sorted: true).should == [["A", "1.0.0"], ["B", "1.0.0"]]
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

    context "and molinillo identifies missing artifacts" do
      let(:graph) do
        graph = Solve::Graph.new
        graph.artifact("A", "1.0.0")
        graph
      end

      let(:demands) { [ ["Z"] ] }

      it "raises an error detailing the missing artifacts" do
        expect(error).to be_a_kind_of(Solve::Errors::NoSolutionError)
        expected_error = <<-ERROR_MESSAGE
Unable to satisfy the following requirements:

- `Z (>= 0.0.0)` required by `Berksfile`
ERROR_MESSAGE
        expect(error.to_s).to eq(expected_error)
      end
    end

    context "and molinillo identifies constraints that exclude all known versions" do
      let(:graph) do
        graph = Solve::Graph.new
        graph.artifact("A", "1.0.0")
        graph
      end

      let(:demands) { [ ["A", "> 1.0.0"] ] }

      it "raises an error detailing the missing artifacts" do
        expect(error).to be_a_kind_of(Solve::Errors::NoSolutionError)
        expected_error = <<-ERROR_MESSAGE
Unable to satisfy the following requirements:

- `A (> 1.0.0)` required by `Berksfile`
ERROR_MESSAGE
        expect(error.to_s).to eq(expected_error)
      end
    end

    context "and molinillo identifies dependency conflicts" do
      let(:graph) do
        graph = Solve::Graph.new
        graph.artifact("A", "1.0.0").depends("B").depends("C")
        graph.artifact("B", "1.0.0").depends("D", "= 1.0.0")
        graph.artifact("C", "1.0.0").depends("D", "= 2.0.0")
        graph.artifact("D", "1.0.0")
        graph.artifact("D", "2.0.0")
        graph
      end

      let(:demands) { [ [ "A" ] ] }

      it "raises an error detailing the missing artifacts" do
        expect(error).to be_a_kind_of(Solve::Errors::NoSolutionError)
        expected_error = <<-ERROR_MESSAGE
Unable to satisfy the following requirements:

- `D (= 1.0.0)` required by `B-1.0.0`
- `D (= 2.0.0)` required by `C-1.0.0`
ERROR_MESSAGE
        expect(error.to_s).to eq(expected_error)
      end
    end
  end

  describe "supporting Serializer interface" do
    let(:serializer) { Solve::Solver::Serializer.new }

    before do
      graph.stub(:artifacts).and_return([])
    end

    it "implements the required interface" do
      problem = Solve::Problem.from_solver(solver)
      json_string = serializer.serialize(problem)
      problem_data = JSON.parse(json_string)
      expected_demands = [
        { "name" => "mysql", "constraint" => ">= 0.0.0" },
        { "name" => "nginx", "constraint" => ">= 0.0.0" },
      ]

      problem_data["demands"].should =~ expected_demands
    end
  end
end
