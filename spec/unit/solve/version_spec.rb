require 'spec_helper'

describe Solve::Version do
  describe "ClassMethods" do
    subject { Solve::Version }

    describe "::new" do
      context "a string containing a major, minor, and patch separated by periods" do
        before(:each) { @version = subject.new("1.2.3") }

        it "assigns a major value" do
          @version.major.should eql(1)
        end

        it "assigns a minor value" do
          @version.minor.should eql(2)
        end

        it "assigns a patch value" do
          @version.patch.should eql(3)
        end
      end

      context "a three element array" do
        before(:each) { @version = subject.new([1,2,3]) }

        it "assigns a major value" do
          @version.major.should eql(1)
        end

        it "assigns a minor value" do
          @version.minor.should eql(2)
        end

        it "assigns a patch value" do
          @version.patch.should eql(3)
        end
      end

      context "a two element array" do
        before(:each) { @version = subject.new([1,2]) }

        it "assigns a major value" do
          @version.major.should eql(1)
        end

        it "assigns a minor value" do
          @version.minor.should eql(2)
        end

        it "sets the patch value to 0 (zero)" do
          @version.patch.should eql(0)
        end
      end

      context "a one element array" do
        before(:each) { @version = subject.new([1]) }

        it "assigns the major value" do
          @version.major.should eql(1)
        end

        it "sets the minor value to 0 (zero)" do
          @version.minor.should eql(0)
        end

        it "sets the patch value to 0 (zero)" do
          @version.patch.should eql(0)
        end        
      end

      context "an empty array" do
        before(:each) { @version = subject.new(Array.new) }

        it "sets the majro value to 0 (zero)" do
          @version.major.should eql(0)
        end

        it "sets the minor value to 0 (zero)" do
          @version.minor.should eql(0)
        end

        it "sets the patch value to 0 (zero)" do
          @version.patch.should eql(0)
        end
      end
    end

    describe "::split" do
      it "returns an array containing 3 elements" do
        subject.split("1.2.0").should have(3).items
      end

      context "given a string only containing a major and minor version" do
        it "returns an array containing 3 elements" do
          subject.split("1.2").should have(3).items
        end

        it "returns nil as the third element" do
          subject.split("1.2")[2].should be_nil
        end
      end

      context "given a string with only a major version" do
        it "raises an InvalidVersionFormat error" do
          lambda {
            subject.split("1")
          }.should raise_error(Solve::InvalidVersionFormat)
        end
      end
    end
  end

  subject { Solve::Version.new("1.0.0") }

  describe "#to_s" do
    it "returns a string containing the major.minor.patch" do
      subject.to_s.should eql("1.0.0")
    end
  end
end
