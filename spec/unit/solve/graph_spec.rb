require 'spec_helper'

describe Solve::Graph do
  subject { Solve::Graph.new }

  describe "#artifact" do
    let(:name) { "nginx" }
    let(:version) { "0.101.5" }

    context "given the artifact of the given name and version does not exist" do
      it "returns a Solve::Artifact" do
        subject.artifact(name, version).should be_a(Solve::Artifact)
      end

      it "the artifact has the given name" do
        subject.artifact(name, version).name.should eql(name)
      end

      it "the artifact has the given version" do
        subject.artifact(name, version).version.to_s.should eql(version)
      end

      it "adds an artifact to the artifacts collection" do
        subject.artifact(name, version)

        subject.artifacts.should have(1).item
      end

      it "the artifact added matches the given name" do
        subject.artifact(name, version)

        subject.artifacts[0].name.should eql(name)
      end

      it "the artifact added matches the given version" do
        subject.artifact(name, version)

        subject.artifacts[0].version.to_s.should eql(version)
      end
    end
  end

  describe "#artifacts" do
    it "returns an array" do
      subject.artifacts.should be_a(Array)
    end

    it "returns an empty array if no artifacts have been accessed" do
      subject.artifacts.should have(0).items
    end

    it "returns an array containing an artifact if one was accessed" do
      subject.artifact("nginx", "0.101.5")

      subject.artifacts.should have(1).item
    end
  end

  describe "#add_artifact" do
    let(:artifact) { double('artifact') }

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
    let(:artifact) { double('artifact') }

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
    let(:artifact) { double('artifact') }

    it "returns true if the given Solve::Artifact is a member of the collection" do
      subject.add_artifact(artifact)

      subject.has_artifact?(artifact).should be_true
    end

    it "returns false if the given Solve::Artifact is not a member of the collection" do
      subject.has_artifact?(artifact).should be_false
    end
  end

  describe "#demand" do
    pending
  end
end
