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
        expect(one).to eq(two)
      end
    end

    context "given an artifact with the same name but different version" do
      let(:one) { Solve::Artifact.new(graph, "riot", "1.0.0") }
      let(:two) { Solve::Artifact.new(graph, "riot", "2.0.0") }

      it "is not equal" do
        expect(one).to_not eq(two)
      end
    end

    context "given an artifact with the same version but different name" do
      let(:one) { Solve::Artifact.new(graph, "riot", "1.0.0") }
      let(:two) { Solve::Artifact.new(graph, "league", "1.0.0") }

      it "is not equal" do
        expect(one).to_not eq(two)
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

      expect(sorted[0]).to eq(one)
      expect(sorted[1]).to eq(two)
      expect(sorted[2]).to eq(three)
    end
  end

  describe "#dependency?" do
    before { subject.depends("nginx", "1.0.0") }

    it "returns false when the dependency does not exist" do
      expect(subject).to have_dependency("nginx", "1.0.0")
    end

    it "returns true when the dependendency exists" do
      expect(subject).to_not have_dependency("apache2", "2.0.0")
    end
  end

  describe "#dependency" do
    before { subject.depends("nginx", "~> 1.2.3") }

    it "returns an instance of Solve::Dependency matching the given name and constraint" do
      dependency = subject.dependency("nginx", "~> 1.2.3")

      expect(dependency).to be_a(Solve::Dependency)
      expect(dependency.name).to eq("nginx")
      expect(dependency.constraint.to_s).to eq("~> 1.2.3")
    end
  end

  describe "#dependencies" do
    it "returns an array" do
      expect(subject.dependencies).to be_a(Array)
    end

    it "returns an empty array if no dependencies have been accessed" do
      expect(subject.dependencies).to be_empty
    end

    it "returns all dependencies" do
      subject.depends("nginx", "1.0.0")
      subject.depends("nginx", "~> 2.0.0")

      expect(subject.dependencies.size).to eq(2)
    end
  end

  describe "#depends" do
    context "given a name and constraint argument" do
      let(:name) { "nginx" }
      let(:constraint) { "~> 1.0.0" }

      context "given the dependency of the given name and constraint does not exist" do
        it "returns a Solve::Artifact" do
          expect(subject.depends(name, constraint)).to be_a(Solve::Artifact)
        end

        it "adds a dependency with the given name and constraint to the list of dependencies" do
          subject.depends(name, constraint)

          expect(subject.dependencies.size).to eq(1)
          expect(subject.dependencies.first.name).to eq(name)
          expect(subject.dependencies.first.constraint.to_s).to eq(constraint)
        end
      end
    end

    context "given only a name argument" do
      it "adds a dependency with a all constraint (>= 0.0.0)" do
        subject.depends("nginx")

        expect(subject.dependencies.size).to eq(1)
        expect(subject.dependencies.first.constraint.to_s).to eq(">= 0.0.0")
      end
    end
  end
end
