require 'spec_helper'

describe Solve::Solver do
  let(:graph) { double('graph') }

  describe "ClassMethods" do
    subject { Solve::Solver }

    describe "::new" do
      let(:demand_array) { ["nginx", "ntp"] }

      it "adds a demand for each element in the array" do
        obj = subject.new(graph, demand_array)

        obj.demands.should have(2).items
      end

      context "when demand_array is an array of array" do
        let(:demand_array) { [["nginx", "= 1.2.3"], ["ntp", "= 1.0.0"]] }

        it "creates a new demand with the name and constraint of each element in the array" do
          obj = subject.new(graph, demand_array)

          obj.demands[0].name.should eql("nginx")
          obj.demands[0].constraint.to_s.should eql("= 1.2.3")
          obj.demands[1].name.should eql("ntp")
          obj.demands[1].constraint.to_s.should eql("= 1.0.0")
        end
      end

      context "when demand_array is an array of strings" do
        let(:demand_array) { ["nginx", "ntp"] }

        it "creates a new demand with the name and a default constraint of each element in the array" do
          obj = subject.new(graph, demand_array)

          obj.demands[0].name.should eql("nginx")
          obj.demands[0].constraint.to_s.should eql(">= 0.0.0")
          obj.demands[1].name.should eql("ntp")
          obj.demands[1].constraint.to_s.should eql(">= 0.0.0")
        end
      end

      context "when demand_array is a mix between an array of arrays and an array of strings" do
        let(:demand_array) { [["nginx", "= 1.2.3"], "ntp"] }

        it "creates a new demand with the name and default constraint or constraint of each element in the array" do
          obj = subject.new(graph, demand_array)

          obj.demands[0].name.should eql("nginx")
          obj.demands[0].constraint.to_s.should eql("= 1.2.3")
          obj.demands[1].name.should eql("ntp")
          obj.demands[1].constraint.to_s.should eql(">= 0.0.0")
        end
      end
    end

    describe "::demand_key" do
      let(:demand) { Solve::Demand.new(double('solver'), "nginx", "= 1.2.3") }

      it "returns a symbol containing the name and constraint of the demand" do
        subject.demand_key(demand).should eql(:'nginx-= 1.2.3')
      end
    end

    describe "::satisfy_all" do
      let(:ver_one) { Solve::Version.new("3.1.1") }
      let(:ver_two) { Solve::Version.new("3.1.2") }

      let(:constraints) do
        [
          Solve::Constraint.new("> 3.0.0"),
          Solve::Constraint.new("<= 3.1.2")
        ]
      end

      let(:versions) do
        [
          Solve::Version.new("0.0.1"),
          Solve::Version.new("0.1.0"),
          Solve::Version.new("1.0.0"),
          Solve::Version.new("2.0.0"),
          Solve::Version.new("3.0.0"),
          ver_one,
          ver_two,
          Solve::Version.new("4.1.0")
        ].shuffle
      end

      it "returns all of the versions which satisfy all of the given constraints" do
        solution = subject.satisfy_all(constraints, versions)

        solution.should have(2).items
        solution.should include(ver_one)
        solution.should include(ver_two)
      end

      context "given multiple duplicate versions" do
        let(:versions) do
          [
            ver_one,
            ver_one,
            ver_one
          ]
        end

        it "does not return duplicate satisfied versions" do
          solution = subject.satisfy_all(constraints, versions)

          solution.should have(1).item
        end
      end
    end

    describe "::satisfy_best" do
      let(:versions) do
        [
          Solve::Version.new("0.0.1"),
          Solve::Version.new("0.1.0"),
          Solve::Version.new("1.0.0"),
          Solve::Version.new("2.0.0"),
          Solve::Version.new("3.0.0"),
          Solve::Version.new("3.1.1"),
          Solve::Version.new("3.1.2"),
          Solve::Version.new("4.1.0")
        ].shuffle
      end

      it "returns the best possible match for the given constraints" do
        subject.satisfy_best([">= 1.0.0", "< 4.1.0"], versions).to_s.should eql("3.1.2")
      end

      context "given no version matches a constraint" do
        let(:versions) do
          [
            Solve::Version.new("4.1.0")
          ]
        end

        it "raises a NoSolutionError error" do
          lambda {
            subject.satisfy_best(">= 5.0.0", versions)
          }.should raise_error(Solve::Errors::NoSolutionError)
        end
      end
    end
  end

  subject { Solve::Solver.new(graph) }

  describe "#resolve" do
    let(:graph) { Solve::Graph.new }

    subject { Solve::Solver.new(graph) }

    before(:each) do
      graph.artifacts("nginx", "1.0.0")
      subject.demands("nginx", "= 1.0.0")
    end

    it "returns a solution in the form of a Hash" do
      subject.resolve.should be_a(Hash)
    end
  end

  describe "#demands" do
    context "given a name and constraint argument" do
      let(:name) { "nginx" }
      let(:constraint) { "~> 0.101.5" }

      context "given the artifact of the given name and constraint does not exist" do
        it "returns a Solve::Demand" do
          subject.demands(name, constraint).should be_a(Solve::Demand)
        end

        it "the artifact has the given name" do
          subject.demands(name, constraint).name.should eql(name)
        end

        it "the artifact has the given constraint" do
          subject.demands(name, constraint).constraint.to_s.should eql(constraint)
        end

        it "adds an artifact to the demands collection" do
          subject.demands(name, constraint)

          subject.demands.should have(1).item
        end

        it "the artifact added matches the given name" do
          subject.demands(name, constraint)

          subject.demands[0].name.should eql(name)
        end

        it "the artifact added matches the given constraint" do
          subject.demands(name, constraint)

          subject.demands[0].constraint.to_s.should eql(constraint)
        end
      end
    end

    context "given only a name argument" do
      it "returns a demand with a match all version constraint (>= 0.0.0)" do
        subject.demands("nginx").constraint.to_s.should eql(">= 0.0.0")
      end
    end

    context "given no arguments" do
      it "returns an array" do
        subject.demands.should be_a(Array)
      end

      it "returns an empty array if no demands have been accessed" do
        subject.demands.should have(0).items
      end

      it "returns an array containing a demand if one was accessed" do
        subject.demands("nginx", "~> 0.101.5")

        subject.demands.should have(1).item
      end
    end

    context "given an unexpected number of arguments" do
      it "raises an ArgumentError if more than two are provided" do
        lambda {
          subject.demands(1, 2, 3)
        }.should raise_error(ArgumentError, "Unexpected number of arguments. You gave: 3. Expected: 2 or less.")
      end

      it "raises an ArgumentError if a name argument of nil is provided" do
        lambda {
          subject.demands(nil)
        }.should raise_error(ArgumentError, "A name must be specified. You gave: [nil].")
      end

      it "raises an ArgumentError if a name and constraint argument are provided but name is nil" do
        lambda {
          subject.demands(nil, "= 1.0.0")
        }.should raise_error(ArgumentError, 'A name must be specified. You gave: [nil, "= 1.0.0"].')
      end
    end
  end

  describe "#add_demand" do
    let(:demand) { Solve::Demand.new(double('graph'), 'ntp') }

    it "adds a Solve::Artifact to the collection of artifacts" do
      subject.add_demand(demand)

      subject.should have_demand(demand)
      subject.demands.should have(1).item
    end

    it "should not add the same demand twice to the collection" do
      subject.add_demand(demand)
      subject.add_demand(demand)

      subject.demands.should have(1).item
    end
  end

  describe "#remove_demand" do
    let(:demand) { Solve::Demand.new(double('graph'), 'ntp') }

    context "given the demand is a member of the collection" do
      before(:each) { subject.add_demand(demand) }

      it "removes the Solve::Artifact from the collection of demands" do
        subject.remove_demand(demand)

        subject.demands.should have(0).items
      end

      it "returns the removed Solve::Artifact" do
        subject.remove_demand(demand).should eql(demand)
      end
    end

    context "given the demand is not a member of the collection" do
      it "should return nil" do
        subject.remove_demand(demand).should be_nil
      end
    end
  end

  describe "#has_demand?" do
    let(:demand) { Solve::Demand.new(double('graph'), 'ntp') }

    it "returns true if the given Solve::Artifact is a member of the collection" do
      subject.add_demand(demand)

      subject.has_demand?(demand).should be_true
    end

    it "returns false if the given Solve::Artifact is not a member of the collection" do
      subject.has_demand?(demand).should be_false
    end
  end
end
