require 'spec_helper'

describe Solve::Version do
  describe "ClassMethods" do
    subject { Solve::Version }

    describe "::from_sring" do
      it "returns an array containing 3 elements" do
        subject.from_string("1.2.0").should have(3).items
      end

      context "given a string only containing a major and minor version" do
        it "returns an array containing 3 elements" do
          subject.from_string("1.2").should have(3).items
        end

        it "returns a Zero as the third element" do
          subject.from_string("1.2")[2].should eql(0)
        end
      end

      context "given a string with only a major version" do
        it "raises an InvalidVersionFormat error" do
          lambda {
            subject.from_string("1")
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
