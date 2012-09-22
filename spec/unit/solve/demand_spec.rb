require 'spec_helper'

describe Solve::Demand do
  let(:graph) { double('graph') }
  let(:name) { "league" }

  describe "ClassMethods" do
    subject { Solve::Demand }

    describe "::new" do
      it "accepts a string for the constraint parameter" do
        subject.new(graph, name, "= 0.0.1").constraint.to_s.should eql("= 0.0.1")
      end

      it "accepts a Solve::Constraint for the constraint parameter" do
        constraint = Solve::Constraint.new("= 0.0.1")

        subject.new(graph, name, constraint).constraint.should eql(constraint)
      end

      context "when no value for 'constraint' is given" do
        it "uses a default of >= 0.0.0" do
          demand = subject.new(graph, name)

          demand.constraint.operator.should eql(">=")
          demand.constraint.version.to_s.should eql("0.0.0")
        end
      end
    end
  end

  let(:constraint) { "~> 1.0.0" }
  subject { Solve::Demand.new(graph, name, constraint) }

  describe "#delete" do
    context "given the artifact is a member of a graph" do
      subject { Solve::Demand.new(graph, name, constraint) }

      before(:each) do
        graph.should_receive(:remove_demand).with(subject).and_return(subject)
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
      subject { Solve::Demand.new(nil, name, constraint) }

      it "returns nil" do
        subject.delete.should be_nil
      end
    end
  end
end
