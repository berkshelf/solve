require 'spec_helper'

describe Solve::Constraint do
  let(:valid_string) { ">= 0.0.0" }
  let(:invalid_string) { "123u7089213.*" }

  describe "ClassMethods" do
    subject { Solve::Constraint }

    describe "#parse" do
      it "returns an array containing two items" do
        subject.parse(valid_string).should have(2).items
      end

      it "returns the operator at index 0" do
        subject.parse(valid_string)[0].should eql(">=")
      end

      it "returns the version string at index 1" do
        subject.parse(valid_string)[1].should eql("0.0.0")
      end

      context "given a string that does not match the Constraint REGEXP" do
        it "returns nil" do
          subject.parse(invalid_string).should be_nil
        end
      end
    end

    describe "#initialize" do
      it "returns a new instance of Constraint" do
        subject.new(valid_string).should be_a(Solve::Constraint)
      end

      it "assigns the parsed operator to the operator attribute" do
        subject.new(valid_string).operator.should eql(">=")
      end

      it "assigns the parsed version string as an instance of Version to the version attribute" do
        result = subject.new(valid_string)

        result.version.should be_a(Solve::Version)
        result.version.to_s.should eql("0.0.0")
      end

      context "given a string that does not match the Constraint REGEXP" do
        it "raises an InvalidConstraintFormat error" do
          lambda {
            subject.new(invalid_string)
          }.should raise_error(Solve::InvalidConstraintFormat)
        end
      end

      context "given a nil value" do
        it "raises an InvalidConstraintFormat error" do
          lambda {
            subject.new(nil)
          }.should raise_error(Solve::InvalidConstraintFormat)
        end
      end
    end
  end
end
