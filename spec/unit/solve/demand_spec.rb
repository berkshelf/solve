require 'spec_helper'

describe Solve::Demand do
  let(:solver) { double('solver') }
  let(:name) { "league" }

  describe "#initialize" do
    it "accepts a string for the constraint parameter" do
      demand = Solve::Demand.new(solver, name, "= 0.0.1")
      expect(demand.constraint.to_s).to eq("= 0.0.1")
    end

    it "accepts a Semverse::Constraint for the constraint parameter" do
      constraint = Semverse::Constraint.new("= 0.0.1")
      demand = Solve::Demand.new(solver, name, constraint)

      expect(demand.constraint).to eq(constraint)
    end

    context "when no value for 'constraint' is given" do
      it "uses a default of >= 0.0.0" do
        demand = Solve::Demand.new(solver, name)

        expect(demand.constraint.operator).to eq(">=")
        expect(demand.constraint.version.to_s).to eq("0.0.0")
      end
    end
  end

  let(:constraint) { "~> 1.0.0" }
  subject { Solve::Demand.new(solver, name, constraint) }

  describe "equality" do
    it "returns true when other is a Solve::Demand with the same name and constriant" do
      other = Solve::Demand.new(solver, name, constraint)
      expect(subject).to eq(other)
    end

    it "returns false when other isn't a Solve::Demand" do
      expect(subject).to_not eq("chicken")
    end

    it "returns false when other is a Solve::Demand with the same name but a different constraint" do
      other = Solve::Demand.new(solver, name, "< 3.4.5")
      expect(subject).to_not eq(other)
    end

    it "returns false when other is a Solve::Demand with the same constraint but a different name" do
      other = Solve::Demand.new(solver, "chicken", constraint)
      expect(subject).to_not eq(other)
    end
  end
end
