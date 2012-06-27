require 'spec_helper'

describe Solve do
  describe "ClassMethods" do
    subject { Solve }

    let(:graph) { double('graph') }

    describe "#it" do
      it "returns nil if a solution does not exist" do
        subject.it(graph).should be_nil
      end
    end

    describe "#it!" do      
      it "raises NoSolutionError if a solution does not exist" do
        lambda {
          subject.it!(graph)
        }.should raise_error(Solve::NoSolutionError)
      end
    end
  end
end
