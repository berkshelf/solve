require 'spec_helper'

describe Solve::Constraint do
  let(:valid_string) { ">= 0.0.0" }
  let(:invalid_string) { "x23u7089213.*" }

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

      context "given a string that does not contain an operator" do
        it "returns a constraint constraint with a default operator (=)" do
          subject.parse("1.0.0")[0].should eql("=")
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

  describe "#satisfies?" do
    subject { Solve::Constraint.new("= 1.0.0") }

    it "accepts a String for version" do
      subject.satisfies?("1.0.0").should be_true
    end

    it "accepts a Version for version" do
      subject.satisfies?(Solve::Version.new("1.0.0")).should be_true
    end

    context "strictly greater than (>)" do
      subject { Solve::Constraint.new("> 1.0.0") }

      it "returns true if the given version would satisfy the constraint" do
        subject.satisfies?("2.0.0").should be_true
      end

      it "returns false if the given version would not satisfy the constraint" do
        subject.satisfies?("1.0.0").should be_false
      end
    end

    context "strictly less than (<)" do
      subject { Solve::Constraint.new("< 1.0.0") }

      it "returns true if the given version would satisfy the constraint" do
        subject.satisfies?("0.1.0").should be_true
      end

      it "returns false if the given version would not satisfy the constraint" do
        subject.satisfies?("1.0.0").should be_false
      end
    end

    context "strictly equal to (=)" do
      subject { Solve::Constraint.new("= 1.0.0") }

      it "returns true if the given version would satisfy the constraint" do
        subject.satisfies?("1.0.0").should be_true
      end

      it "returns false if the given version would not satisfy the constraint" do
        subject.satisfies?("1.0.1").should be_false
      end
    end

    context "greater than or equal to (>=)" do
      subject { Solve::Constraint.new(">= 1.0.0") }

      it "returns true if the given version is greater than the version constraint" do
        subject.satisfies?("2.0.0").should be_true
      end

      it "returns true if the given version is equal to the version constraint" do
        subject.satisfies?("1.0.0").should be_true
      end

      it "returns false if the given version is less than the version constraint" do
        subject.satisfies?("0.9.0").should be_false
      end
    end

    context "greater than or equal to (<=)" do
      subject { Solve::Constraint.new("<= 1.0.0") }

      it "returns true if the given version is less than the version constraint" do
        subject.satisfies?("0.9.0").should be_true
      end

      it "returns true if the given version is equal to the version constraint" do
        subject.satisfies?("1.0.0").should be_true
      end

      it "returns false if the given version is less than the version constraint" do
        subject.satisfies?("1.0.1").should be_false
      end
    end

    context "greater than or equal to (~>)" do
      subject { Solve::Constraint.new("~> 1.0.0") }

      it "returns true if the given version is equal to the version constraint" do
        subject.satisfies?("1.0.0").should be_true
      end

      context "when the last value in the constraint is for patch" do
        subject { Solve::Constraint.new("~> 1.0.1") }

        it "returns true if the patch level is greater than the constraint's" do
          subject.satisfies?("1.0.2").should be_true
        end

        it "returns true if the patch level is equal to the constraint's" do
          subject.satisfies?("1.0.1").should be_true
        end

        it "returns false if the patch level is less than the constraint's" do
          subject.satisfies?("1.0.0").should be_false
        end

        it "returns false if the given version is less than the constraint's" do
          subject.satisfies?("0.9.0").should be_false
        end
      end

      context "when the last value in the constraint is for minor" do
        subject { Solve::Constraint.new("~> 1.1") }

        it "returns true if the minor level is greater than the constraint's" do
          subject.satisfies?("1.2").should be_true
        end

        it "returns true if the minor level is equal to the constraint's" do
          subject.satisfies?("1.1").should be_true
        end

        it "returns true if a patch level is set but the minor level is equal to or greater than the constraint's" do
          subject.satisfies?("1.2.8").should be_true
        end

        it "returns false if the patch level is less than the constraint's" do
          subject.satisfies?("1.0.1").should be_false
        end

        it "returns false if the major level is greater than the constraint's" do
          subject.satisfies?("2.0.0").should be_false
        end
      end
    end
  end
end
