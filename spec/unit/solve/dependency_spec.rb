require 'spec_helper'

describe Solve::Dependency do
  let(:artifact) { Solve::Artifact.new("league") }

  subject { Solve::Dependency.new(artifact, "~> 0.0.1") }

  describe "#eql?" do
    it "returns true if the other object is an instance of Solve::Dependency with the same constraint and artifact" do
      other = Solve::Dependency.new(artifact, "~> 0.0.1")

      subject.should eql(other)
    end
  end
end
