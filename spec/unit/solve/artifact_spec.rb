require 'spec_helper'

describe Solve::Artifact do
  let(:graph) do
    package = double('package')
    package_version = double('package_version')
    package_version.stub(:dependencies).and_return([])
    package.stub(:add_version).and_return(package_version)
    double('graph', dep_graph: double('dep_graph', package: package))
  end

  let(:name) { "league" }
  let(:version) { "1.0.0" }
  subject { Solve::Artifact.new(graph, name, version) }

  describe "equality" do
    context "given an artifact with the same name and version" do
      let(:one) { Solve::Artifact.new(graph, "riot", "1.0.0") }
      let(:two) { Solve::Artifact.new(graph, "riot", "1.0.0") }

      it "is equal" do
        one.should be_eql(two)
      end
    end

    context "given an artifact with the same name but different version" do
      let(:one) { Solve::Artifact.new(graph, "riot", "1.0.0") }
      let(:two) { Solve::Artifact.new(graph, "riot", "2.0.0") }

      it "is not equal" do
        one.should_not be_eql(two)
      end
    end

    context "given an artifact with the same version but different name" do
      let(:one) { Solve::Artifact.new(graph, "riot", "1.0.0") }
      let(:two) { Solve::Artifact.new(graph, "league", "1.0.0") }

      it "is not equal" do
        one.should_not be_eql(two)
      end
    end
  end

  describe "sorting" do
    let(:one) { Solve::Artifact.new(graph, "riot", "1.0.0") }
    let(:two) { Solve::Artifact.new(graph, "riot", "2.0.0") }
    let(:three) { Solve::Artifact.new(graph, "riot", "3.0.0") }

    let(:artifacts) do
      [
        one,
        two,
        three
      ].shuffle
    end

    it "orders artifacts by their version number" do
      sorted = artifacts.sort

      sorted[0].should eql(one)
      sorted[1].should eql(two)
      sorted[2].should eql(three)
    end
  end

  describe "#dependencies" do
    context "given no arguments" do
      it "returns an array" do
        subject.dependencies.should be_a(Array)
      end

      it "returns an empty array if no dependencies have been accessed" do
        subject.dependencies.should have(0).items
      end
    end
  end

  describe "#depends" do
    context "given a name and constraint argument" do
      let(:name) { "nginx" }
      let(:constraint) { "~> 0.101.5" }

      context "given the dependency of the given name and constraint does not exist" do
        it "returns a Solve::Artifact" do
          subject.depends(name, constraint).should be_a(Solve::Artifact)
        end

        it "adds a dependency with the given name and constraint to the list of dependencies" do
          subject.depends(name, constraint)

          subject.dependencies.should have(1).item
          subject.dependencies.first.name.should eql(name)
          subject.dependencies.first.constraint.to_s.should eql(constraint)
        end
      end
    end

    context "given only a name argument" do
      it "adds a dependency with a all constraint (>= 0.0.0)" do
        subject.depends("nginx")

        subject.dependencies.should have(1).item
        subject.dependencies.first.constraint.to_s.should eql(">= 0.0.0")
      end
    end
  end

  describe "::get_dependency" do
    before(:each) { subject.depends("nginx", "~> 1.2.3") }

    it "returns an instance of Solve::Dependency matching the given name and constraint" do
      dependency = subject.get_dependency("nginx", "~> 1.2.3")

      dependency.should be_a(Solve::Dependency)
      dependency.name.should eql("nginx")
      dependency.constraint.to_s.should eql("~> 1.2.3")
    end
  end

  describe "#delete" do
    context "given the artifact is a member of a graph" do
      subject { Solve::Artifact.new(graph, name, version) }

      before(:each) do
        graph.should_receive(:remove_artifact).with(subject).and_return(subject)
      end

      it "notifies the graph that the artifact should be removed" do
        subject.delete
      end

      it "sets the graph attribute to nil" do
        subject.delete

        subject.graph.should be_nil
      end

      it "returns the instance of artifact deleted from the graph" do
        subject.delete.should eql(subject)
      end
    end

    context "given the artifact is not the member of a graph" do
      subject { Solve::Artifact.new(nil, name, version) }

      it "returns nil" do
        subject.delete.should be_nil
      end
    end
  end
end
