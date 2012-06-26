require 'spec_helper'

describe Solve::Artifact do
  let(:graph) { Solve::Graph.new }
  let(:name) { "league" }
  let(:version) { "1.0.0" }
  subject { Solve::Artifact.new(graph, name, version) }

  describe "#remove", focus: true do
    context "given the artifact exists" do
      it "removes the artifact from the collection" do
        graph.artifacts.should be_empty
        subject.delete

        subject.graph.should be_nil
      end
    end
  end
end
