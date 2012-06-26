require 'spec_helper'

describe Solve do
  describe "ClassMethods" do
    subject { Solve }

    describe "#it" do
      pending
    end

    describe "#it!" do
      let(:graph) { double('graph') }
      
      it "raises NoSolutionError if a solution does not exist" do
        lambda {
          subject.it!(graph)
        }.should raise_error(Solve::NoSolutionError)
      end
    end
  end
end
