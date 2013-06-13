require 'spec_helper'

describe Solve::Demand do
  let(:solver) { double('solver') }
  let(:name) { "league" }

  describe "ClassMethods" do
    subject { Solve::Demand }

    describe "::new" do
      it "accepts a string for the constraint parameter" do
        subject.new(solver, name, "= 0.0.1").constraint.to_s.should eql("= 0.0.1")
      end

      it "accepts a Solve::Constraint for the constraint parameter" do
        constraint = Solve::Constraint.new("= 0.0.1")

        subject.new(solver, name, constraint).constraint.should eql(constraint)
      end

      context "when no value for 'constraint' is given" do
        it "uses a default of >= 0.0.0" do
          demand = subject.new(solver, name)

          demand.constraint.operator.should eql(">=")
          demand.constraint.version.to_s.should eql("0.0.0")
        end
      end
    end
  end

  let(:constraint) { "~> 1.0.0" }
  subject { Solve::Demand.new(solver, name, constraint) }

  describe "#delete" do
    context "given the demand is related to a solver" do
      subject { Solve::Demand.new(solver, name, constraint) }

      before(:each) do
        solver.should_receive(:remove_demand).with(subject).and_return(subject)
      end

      it "notifies the solver that the demand should be removed" do
        subject.delete
      end

      it "sets the solver attribute to nil" do
        subject.delete

        subject.solver.should be_nil
      end

      it "returns the instance of demand deleted from the solver" do
        subject.delete.should eql(subject)
      end
    end

    context "given the demand is not the member of a solver" do
      subject { Solve::Demand.new(nil, name, constraint) }

      it "returns nil" do
        subject.delete.should be_nil
      end
    end
  end

  describe "equality" do
    it "returns true when other is a Solve::Demand with the same name and constriant" do
      other = Solve::Demand.new(solver, name, constraint)

      subject.should eql(other)
    end

    it "returns false when other isn't a Solve::Demand" do
      subject.should_not eql("chicken")
    end

    it "returns false when other is a Solve::Demand with the same name but a different constraint" do
      other = Solve::Demand.new(solver, name, "< 3.4.5")

      subject.should_not eql(other)
    end

    it "returns false when other is a Solve::Demand with the same constraint but a different name" do
      other = Solve::Demand.new(solver, "chicken", constraint)

      subject.should_not eql(other)
    end
  end
end
