require 'spec_helper'

describe Solve::Graph do
  describe "ClassMethods" do
    subject { Solve::Graph }

    describe "::key_for" do
      context "given a Solve::Artifact" do
        let(:artifact) { Solve::Artifact.new(double('graph'), "nginx", "1.2.3") }

        it "delegates to ::artifact_key with the name and version of the artifact" do
          subject.should_receive(:artifact_key).with(artifact.name, artifact.version)

          subject.key_for(artifact)
        end
      end

      context "given a Solve::Dependency" do
        let(:demand) { Solve::Dependency.new(double('artifact'), "ntp", "= 2.3.4") }

        it "delegates to ::dependency_key with the name and constraint of the dependency" do
          subject.should_receive(:dependency_key).with(demand.name, anything)

          subject.key_for(demand)
        end
      end

      context "given an unknown object" do
        it "raises an ArgumentError" do
          lambda {
            subject.key_for("hello")
          }.should raise_error(ArgumentError)
        end
      end
    end

    describe "::artifact_key" do
      it "returns a symbol containing the name and version of the artifact" do
        subject.artifact_key("nginx", "1.2.3").should eql(:'nginx-1.2.3')
      end
    end

    describe "::dependency_key" do
      it "returns a symbol containing the name and constraint of the dependency" do
        subject.dependency_key("ntp", "= 2.3.4").should eql(:'ntp-= 2.3.4')
      end
    end
  end

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

  describe "#get_artifact" do
    before(:each) do
      subject.artifacts("nginx", "1.0.0")
    end

    it "returns an instance of artifact of the matching name and version" do
      artifact = subject.get_artifact("nginx", "1.0.0")

      artifact.should be_a(Solve::Artifact)
      artifact.name.should eql("nginx")
      artifact.version.to_s.should eql("1.0.0")
    end

    context "when an artifact of the given name is not in the collection of artifacts" do
      it "returns nil" do
        subject.get_artifact("nothere", "1.0.0").should be_nil
      end
    end
  end

  describe "#versions" do
    let(:artifacts) do
      [
        double('artifact', name: 'nginx', version: Solve::Version.new('1.0.0')),
        double('artifact', name: 'nginx', version: Solve::Version.new('2.0.0')),
        double('artifact', name: 'nginx', version: Solve::Version.new('3.0.0')),
        double('artifact', name: 'nginx', version: Solve::Version.new('4.0.0')),
        double('artifact', name: 'nginx', version: Solve::Version.new('5.0.0')),
        double('artifact', name: 'mysql', version: Solve::Version.new('4.0.0'))
      ]
    end

    before(:each) do
      subject.stub(:artifacts).and_return(artifacts)
    end

    it "returns all the artifacts matching the given name" do
      subject.versions("nginx").should have(5).items
    end

    context "given an optional constraint value" do
      it "returns only the artifacts matching the given constraint value and name" do
        subject.versions("nginx", ">= 4.0.0").should have(2).items
      end
    end
  end

  describe "#add_artifact" do
    let(:artifact) { Solve::Artifact.new(double('graph'), "nginx", "1.0.0") }

    it "adds a Solve::Artifact to the collection of artifacts" do
      subject.add_artifact(artifact)

      subject.should have_artifact(artifact.name, artifact.version)
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

      subject.has_artifact?(artifact.name, artifact.version).should be_true
    end

    it "returns false if the given Solve::Artifact is not a member of the collection" do
      subject.has_artifact?(artifact.name, artifact.version).should be_false
    end
  end

  describe "eql?" do
    subject do
      graph = Solve::Graph.new
      graph.artifacts("A", "1.0.0").depends("B", "1.0.0")
      graph.artifacts("A", "2.0.0").depends("C", "1.0.0")
      graph
    end

    it "returns false if other isn't a Solve::Graph" do
      subject.should_not be_eql("chicken")
    end

    it "returns true if other is a Solve::Graph with the same artifacts and dependencies" do
      other = Solve::Graph.new
      other.artifacts("A", "1.0.0").depends("B", "1.0.0")
      other.artifacts("A", "2.0.0").depends("C", "1.0.0")

      subject.should eql(other)
    end

    it "returns false if the other is a Solve::Graph with the same artifacts but different dependencies" do
      other = Solve::Graph.new
      other.artifacts("A", "1.0.0")
      other.artifacts("A", "2.0.0")

      subject.should_not eql(other)
    end

    it "returns false if the other is a Solve::Graph with the same dependencies but different artifacts" do
      other = Solve::Graph.new
      other.artifacts("A", "1.0.0").depends("B", "1.0.0")
      other.artifacts("A", "2.0.0").depends("C", "1.0.0")
      other.artifacts("B", "1.0.0")

      subject.should_not eql(other)
    end
  end
end
