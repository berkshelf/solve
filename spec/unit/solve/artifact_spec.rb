require 'spec_helper'

describe Solve::Artifact do
  let(:graph) { double('graph') }
  let(:name) { "league" }
  let(:version) { "1.0.0" }
  subject { Solve::Artifact.new(graph, name, version) }

  describe "#dependencies" do
    context "given a name and constraint argument" do
      let(:name) { "nginx" }
      let(:constraint) { "~> 0.101.5" }

      context "given the dependency of the given name and constraint does not exist" do
        it "returns a Solve::Artifact" do
          subject.dependencies(name, constraint).should be_a(Solve::Dependency)
        end

        it "the dependency has the given name" do
          subject.dependencies(name, constraint).name.should eql(name)
        end

        it "the dependency has the given constraint" do
          subject.dependencies(name, constraint).constraint.to_s.should eql(constraint)
        end

        it "adds an dependency to the dependency collection" do
          subject.dependencies(name, constraint)

          subject.dependencies.should have(1).item
        end

        it "the dependency added matches the given name" do
          subject.dependencies(name, constraint)

          subject.dependencies[0].name.should eql(name)
        end

        it "the dependency added matches the given constraint" do
          subject.dependencies(name, constraint)

          subject.dependencies[0].constraint.to_s.should eql(constraint)
        end
      end
    end

    context "given no arguments" do
      it "returns an array" do
        subject.dependencies.should be_a(Array)
      end

      it "returns an empty array if no dependencies have been accessed" do
        subject.dependencies.should have(0).items
      end

      it "returns an array containing an dependency if one was accessed" do
        subject.dependencies("nginx", "~> 0.101.5")

        subject.dependencies.should have(1).item
      end
    end

    context "given only a name argument" do
      it "returns an array containing a match all constraint (>= 0.0.0)" do
        subject.dependencies("nginx").constraint.to_s.should eql(">= 0.0.0")
      end
    end

    context "given an unexpected number of arguments" do
      it "raises an ArgumentError if more than two are provided" do
        lambda {
          subject.dependencies(1, 2, 3)
        }.should raise_error(ArgumentError, "Unexpected number of arguments. You gave: 3. Expected: 2 or less.")
      end

      it "raises an ArgumentError if one argument is provided" do
        lambda {
          subject.dependencies(nil)
        }.should raise_error(ArgumentError, "A name must be specified. You gave: [nil].")
      end

      it "raises an ArgumentError if one of the arguments provided is nil" do
        lambda {
          subject.dependencies(nil, "= 1.0.0")
        }.should raise_error(ArgumentError, 'A name must be specified. You gave: [nil, "= 1.0.0"].')
      end
    end
  end

  describe "#delete" do
    context "given the artifact is a member of a graph" do
      subject { Solve::Artifact.new(graph, name, version) }

      before(:each) do
        graph.should_receive(:remove_artifact).with(subject).and_return(subject)
      end

      it "notifies the graph that the artifact should be removed" do
        subject.delete
      end

      it "sets the graph attribute to nil" do
        subject.delete

        subject.graph.should be_nil
      end

      it "returns the instance of artifact deleted from the graph" do
        subject.delete.should eql(subject)
      end
    end

    context "given the artifact is not the member of a graph" do
      subject { Solve::Artifact.new(nil, name, version) }

      it "returns nil" do
        subject.delete.should be_nil
      end
    end
  end
end
