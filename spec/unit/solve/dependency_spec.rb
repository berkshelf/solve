require 'spec_helper'

describe Solve::Dependency do
  describe "ClassMethods" do
    subject { Solve::Dependency }

    describe "::new" do
      context "when no value for 'constraint' is given" do
        it "uses a default of >= 0.0.0" do
          dep = subject.new(double('artifact'), "ntp")

          dep.constraint.operator.should eql(">=")
          dep.constraint.version.to_s.should eql("0.0.0")
        end
      end
    end
  end

  let(:artifact) { double('artifact') }
  let(:name) { 'nginx' }
  let(:constraint) { "~> 0.0.1" }

  subject { Solve::Dependency.new(artifact, name, constraint) }

  describe "#eql?" do
    it "returns true if the other object is an instance of Solve::Dependency with the same constraint and artifact" do
      other = Solve::Dependency.new(artifact, name, constraint)

      subject.should eql(other)
    end
  end
end
