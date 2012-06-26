require 'spec_helper'

describe Solve::Version do
  subject { Solve::Version.new("1.0.0") }

  describe "#to_s" do
    it "returns a string containing the major.minor.patch" do
      subject.to_s.should eql("1.0.0")
    end
  end
end
