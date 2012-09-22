require 'spec_helper'

describe Solve::Graph do
  subject { Solve::Graph.new }

  describe "#artifacts" do
    context "given a name and version argument" do
      let(:name) { "nginx" }
      let(:version) { "0.101.5" }

      context "given the artifact of the given name and version does not exist" do
        it "returns a Solve::Artifact" do
          subject.artifacts(name, version).should be_a(Solve::Artifact)
        end

        it "the artifact has the given name" do
          subject.artifacts(name, version).name.should eql(name)
        end

        it "the artifact has the given version" do
          subject.artifacts(name, version).version.to_s.should eql(version)
        end

        it "adds an artifact to the artifacts collection" do
          subject.artifacts(name, version)

          subject.artifacts.should have(1).item
        end

        it "the artifact added matches the given name" do
          subject.artifacts(name, version)

          subject.artifacts[0].name.should eql(name)
        end

        it "the artifact added matches the given version" do
          subject.artifacts(name, version)

          subject.artifacts[0].version.to_s.should eql(version)
        end
      end
    end

    context "given no arguments" do
      it "returns an array" do
        subject.artifacts.should be_a(Array)
      end

      it "returns an empty array if no artifacts have been accessed" do
        subject.artifacts.should have(0).items
      end

      it "returns an array containing an artifact if one was accessed" do
        subject.artifacts("nginx", "0.101.5")

        subject.artifacts.should have(1).item
      end
    end

    context "given an unexpected number of arguments" do
      it "raises an ArgumentError if more than two are provided" do
        lambda {
          subject.artifacts(1, 2, 3)
        }.should raise_error(ArgumentError, "Unexpected number of arguments. You gave: 3. Expected: 0 or 2.")
      end

      it "raises an ArgumentError if one argument is provided" do
        lambda {
          subject.artifacts(nil)
        }.should raise_error(ArgumentError, "Unexpected number of arguments. You gave: 1. Expected: 0 or 2.")
      end

      it "raises an ArgumentError if one of the arguments provided is nil" do
        lambda {
          subject.artifacts("nginx", nil)
        }.should raise_error(ArgumentError, 'A name and version must be specified. You gave: ["nginx", nil].')
      end
    end
  end

  describe "#add_artifact" do
    let(:artifact) { Solve::Artifact.new(double('graph'), "nginx", "1.0.0") }

    it "adds a Solve::Artifact to the collection of artifacts" do
      subject.add_artifact(artifact)

      subject.should have_artifact(artifact)
      subject.artifacts.should have(1).item
    end

    it "should not add the same artifact twice to the collection" do
      subject.add_artifact(artifact)
      subject.add_artifact(artifact)

      subject.artifacts.should have(1).item
    end
  end

  describe "#remove_artifact" do
    let(:artifact) { Solve::Artifact.new(double('graph'), "nginx", "1.0.0") }

    context "given the artifact is a member of the collection" do
      before(:each) { subject.add_artifact(artifact) }

      it "removes the Solve::Artifact from the collection of artifacts" do
        subject.remove_artifact(artifact)

        subject.artifacts.should have(0).items
      end

      it "returns the removed Solve::Artifact" do
        subject.remove_artifact(artifact).should eql(artifact)
      end
    end

    context "given the artifact is not a member of the collection" do
      it "should return nil" do
        subject.remove_artifact(artifact).should be_nil
      end
    end
  end

  describe "#has_artifact?" do
    let(:artifact) { Solve::Artifact.new(double('graph'), "nginx", "1.0.0") }

    it "returns true if the given Solve::Artifact is a member of the collection" do
      subject.add_artifact(artifact)

      subject.has_artifact?(artifact).should be_true
    end

    it "returns false if the given Solve::Artifact is not a member of the collection" do
      subject.has_artifact?(artifact).should be_false
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
