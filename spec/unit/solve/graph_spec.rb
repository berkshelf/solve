require "spec_helper"

describe Solve::Graph do
  describe "#artifact?" do
    it "returns true if the given Solve::Artifact is a member of the collection" do
      subject.artifact("nginx", "1.0.0")
      expect(subject).to have_artifact("nginx", "1.0.0")
    end

    it "returns false if the given Solve::Artifact is not a member of the collection" do
      expect(subject).to_not have_artifact("apache", "1.0.0")
      expect(subject).to_not have_artifact("nginx", "11.4.4")
    end
  end

  describe "#find" do
    before { subject.artifact("nginx", "1.0.0") }

    it "returns an instance of artifact of the matching name and version" do
      artifact = subject.find("nginx", "1.0.0")

      expect(artifact).to be_a(Solve::Artifact)
      expect(artifact.name).to eq("nginx")
      expect(artifact.version.to_s).to eq("1.0.0")
    end

    it "returns nil when the artifact does not exist" do
      expect(subject.find("notthere", "1.0.0")).to be_nil
    end
  end

  describe "#artifact" do
    let(:name)    { "nginx" }
    let(:version) { "1.0.0" }

    context "given the artifact of the given name and version does not exist" do
      it "returns a Solve::Artifact" do
        expect(subject.artifact(name, version)).to be_a(Solve::Artifact)
      end

      it "the artifact has the given name" do
        artifact = subject.artifact(name, version)
        expect(artifact.name).to eq(name)
      end

      it "the artifact has the given version" do
        artifact = subject.artifact(name, version)
        expect(artifact.version.to_s).to eq(version)
      end

      it "adds an artifact to the artifacts collection" do
        subject.artifact(name, version)
        expect(subject).to have_artifact(name, version)
      end
    end
  end

  describe "#artifacts" do
    it "returns an array" do
      expect(subject.artifacts).to be_a(Array)
    end

    it "returns an empty array if no artifacts have been accessed" do
      expect(subject.artifacts).to be_empty
    end

    it "returns an array containing an artifact if one was accessed" do
      subject.artifact("nginx", "1.0.0")
      expect(subject.artifacts.size).to eq(1)
    end
  end

  describe "#versions" do
    before do
      subject.artifact('nginx', '1.0.0')
      subject.artifact('nginx', '2.0.0')
      subject.artifact('nginx', '3.0.0')
      subject.artifact('nginx', '4.0.0')

      subject.artifact('other', '1.0.0')
    end

    it "returns all the artifacts matching the given name" do
      expect(subject.versions("nginx").size).to eq(4)
    end

    it "does not satisfy constraints if it is the default" do
      constraint = Semverse::Constraint.new(Semverse::DEFAULT_CONSTRAINT.to_s)
      expect(constraint).to_not receive(:satisfies?)
      subject.versions("nginx")
    end

    it "returns only matching constraints if one is given" do
      expect(subject.versions("nginx", ">= 3.0.0").size).to eq(2)
    end
  end

  describe "==" do
    def make_graph
      graph = Solve::Graph.new
      graph.artifact("A" ,"1.0.0").depends("B", "1.0.0")
      graph.artifact("A" ,"2.0.0").depends("C", "1.0.0")
      graph
    end

    subject { make_graph }

    it "returns false if other isn't a Solve::Graph" do
      expect(subject).to_not eq("chicken")
    end

    it "returns true if the other is the same" do
      expect(subject).to eq(make_graph)
    end

    it "returns false if the other has the same artifacts but different dependencies" do
      other = make_graph
      other.artifact("A", "1.0.0").depends("D", "1.0.0")

      expect(subject).to_not eq(other)
    end

    it "returns false if the other has the same dependencies but different artifacts" do
      other = make_graph
      other.artifact("E", "1.0.0")

      expect(subject).to_not eq(other)
    end
  end
end
