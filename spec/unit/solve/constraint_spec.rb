require 'spec_helper'

describe Solve::Constraint do
  let(:valid_string) { ">= 0.0.0" }
  let(:invalid_string) { "x23u7089213.*" }

  describe "ClassMethods" do
    subject { Solve::Constraint }

    describe "::new" do
      it "returns a new instance of Constraint" do
        subject.new(valid_string).should be_a(Solve::Constraint)
      end

      it "assigns the parsed operator to the operator attribute" do
        subject.new(valid_string).operator.should eql(">=")
      end

      it "assigns the parsed operator to the operator attribute with no separation between operator and version" do
        subject.new(">=0.0.0").operator.should eql(">=")
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
          }.should raise_error(Solve::Errors::InvalidConstraintFormat)
        end
      end

      context "given a nil value" do
        it "raises an InvalidConstraintFormat error" do
          lambda {
            subject.new(nil)
          }.should raise_error(Solve::Errors::InvalidConstraintFormat)
        end
      end

      context "given a string containing only a major and minor version" do
        it "has a nil value for patch" do
          subject.new("~> 1.2").patch.should be_nil
        end
      end
    end

    describe "::split" do
      it "returns an array containing two items" do
        subject.split(valid_string).should have(2).items
      end

      it "returns the operator at index 0" do
        subject.split(valid_string)[0].should eql(">=")
      end

      it "returns the version string at index 1" do
        subject.split(valid_string)[1].should eql("0.0.0")
      end

      context "given a string that does not match the Constraint REGEXP" do
        it "returns nil" do
          subject.split(invalid_string).should be_nil
        end
      end

      context "given a string that does not contain an operator" do
        it "returns a constraint constraint with a default operator (=)" do
          subject.split("1.0.0")[0].should eql("=")
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
      subject { Solve::Constraint.new("> 1.0.0-alpha") }

      it "returns true if the given version would satisfy the constraint" do
        subject.satisfies?("2.0.0").should be_true
      end

      it "returns true if the given version would satisfy the constraint (2)" do
        subject.satisfies?("1.0.0").should be_true
      end

      it "returns false if the given version would not satisfy the constraint" do
        subject.satisfies?("1.0.0-alpha").should be_false
      end
    end

    context "strictly less than (<)" do
      subject { Solve::Constraint.new("< 1.0.0+build.20") }

      it "returns true if the given version would satisfy the constraint" do
        subject.satisfies?("0.1.0").should be_true
      end

      it "returns true if the given version would satisfy the constraint (2)" do
        subject.satisfies?("1.0.0").should be_true
      end

      it "returns false if the given version would not satisfy the constraint" do
        subject.satisfies?("1.0.0+build.21").should be_false
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

      it "returns false if the given version would not satisfy the constraint" do
        subject.satisfies?("1.0.0-alpha").should be_false
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

    # TODO
    # "~> 1.2.3-4" eq               ">= 1.2.3-4 " && "< 1.2.5--"  # note that '-' is a valid non-numeric identifier
    # "~> 1.2.3-alpha" eq           ">= 1.2.3-alpha" && "< 1.2.3"
    # "~> 1.2.3-alpha.4" eq         ">= 1.2.3-alpha.4" && "< 1.2.3-alpha.-"
    # "~> 1.2.3-alpha.4+5" eq       ">= 1.2.3-alpha.4+5" && "< 1.2.3-alpha.4+-"
    # "~> 1.2.3-alpha.4+build" eq   ">= 1.2.3-alpha.4+build < 1.2.3-alpha.5"
    # "~> 1.2.3-alpha.4+build.5" eq ">= 1.2.3-alpha.4+build.5" && "< 1.2.3-alpha.4+build.-"
    # "~> 1.2.3" eq                 ">= 1.2.3" && "< 1.3.0-0"
    # "~> 1.2.3+4" eq               ">= 1.2.3+4" && "< 1.2.3+-"
    # "~> 1.2.3+build" eq           ">= 1.2.3+build" && "< 1.2.4-0"
    # "~> 1.2.3+build.4" eq         ">= 1.2.3+build.4" && "< 1.2.3+build.-"
    # "~> 1.2" eq                   ">= 1.2.0" && "< 2.0.0-0"
    %w[~> ~].each do |operator|
      pending "aproximately (#{operator})" do
        subject { Solve::Constraint.new("#{operator} 1.0.0") }

        it "returns true if the given version is equal to the version constraint" do
          subject.satisfies?("1.0.0").should be_true
        end

        context "when the last value in the constraint is for special" do
          subject { Solve::Constraint.new("#{operator} 1.0.0+build.2") }

          it "returns true if the special level is greater than the constraint's" do
            subject.satisfies?("1.0.0+build.3").should be_true
          end

          it "returns true if the special level is equal to the constraint's" do
            subject.satisfies?("1.0.0+build.2").should be_true
          end

          it "returns false if the special level is less than the constraint's" do
            subject.satisfies?("1.0.0+build").should be_false
          end

          it "returns false if the patch level is less than the constraint's" do
            subject.satisfies?("1.0.0").should be_false
          end

          it "returns false if the given version is less than the constraint's" do
            subject.satisfies?("0.9.0").should be_false
          end
        end

        context "when the last value in the constraint is for patch" do
          subject { Solve::Constraint.new("#{operator} 1.0.1") }

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
          subject { Solve::Constraint.new("#{operator} 1.1") }

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

  describe "#eql?" do

    subject { Solve::Constraint.new("= 1.0.0") }

    it "returns true if the other object is a Solve::Constraint with the same operator and version" do
      other = Solve::Constraint.new("= 1.0.0")
      subject.should eql(other)
    end

    it "returns false if the other object is a Solve::Constraint with the same operator and different version" do
      other = Solve::Constraint.new("= 9.9.9")
      subject.should_not eql(other)
    end

    it "returns false if the other object is a Solve::Constraint with the same version and different operator" do
      other = Solve::Constraint.new("> 1.0.0")
      subject.should_not eql(other)
    end

    it "returns false if the other object is not a Solve::Constraint" do
      other = "chicken"
      subject.should_not eql(other)
    end
  end
end
