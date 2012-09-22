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

  describe "#delete" do
    context "given the dependency is a member of an artifact" do
      subject { Solve::Dependency.new(artifact, name, constraint) }

      before(:each) do
        artifact.should_receive(:remove_dependency).with(subject).and_return(subject)
      end

      it "notifies the artifact that the dependency should be removed" do
        subject.delete
      end

      it "sets the artifact attribute to nil" do
        subject.delete

        subject.artifact.should be_nil
      end

      it "returns the instance of dependency deleted from the artifact" do
        subject.delete.should eql(subject)
      end
    end

    context "given the dependency is not the member of an artifact" do
      subject { Solve::Dependency.new(nil, name, constraint) }

      it "returns nil" do
        subject.delete.should be_nil
      end
    end
  end

  describe "#eql?" do
    it "returns true if the other object is an instance of Solve::Dependency with the same constraint and artifact" do
      other = Solve::Dependency.new(artifact, name, constraint)

      subject.should eql(other)
    end
  end
end
