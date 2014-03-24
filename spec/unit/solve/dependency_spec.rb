require 'spec_helper'

describe Solve::Dependency do
  describe "#initialize" do
    it "uses a default of >= 0.0.0" do
      dep = Solve::Dependency.new(double("artifact"), "ntp")

      expect(dep.constraint.operator).to eq(">=")
      expect(dep.constraint.version.to_s).to eq("0.0.0")
    end
  end

  let(:artifact) { double('artifact') }
  let(:name) { 'nginx' }
  let(:constraint) { "~> 0.0.1" }

  subject { Solve::Dependency.new(artifact, name, constraint) }

  describe "#==" do
    it "returns true if the other object is an instance of Solve::Dependency with the same constraint and artifact" do
      other = Solve::Dependency.new(artifact, name, constraint)
      expect(subject).to eq(other)
    end
  end
end
