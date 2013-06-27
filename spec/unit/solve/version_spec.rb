require 'spec_helper'

describe Solve::Version do
  describe "ClassMethods" do
    subject { Solve::Version }

    describe "::new" do
      context "a string containing a major, minor and patch separated by periods a pre-release and a build" do
        before(:each) { @version = subject.new("1.2.3-rc.1+build.1") }

        it "assigns a major value" do
          @version.major.should eql(1)
        end

        it "assigns a minor value" do
          @version.minor.should eql(2)
        end

        it "assigns a patch value" do
          @version.patch.should eql(3)
        end

        it "assigns a pre_release value" do
          @version.pre_release.should eql('rc.1')
        end

        it "assigns a build value" do
          @version.build.should eql('build.1')
        end
      end

      context "a string containing a major, minor and patch separated by periods and a build" do
        before(:each) { @version = subject.new("1.2.3+pre-build.11.e0f985a") }

        it "assigns a major value" do
          @version.major.should eql(1)
        end

        it "assigns a minor value" do
          @version.minor.should eql(2)
        end

        it "assigns a patch value" do
          @version.patch.should eql(3)
        end

        it "doesn't assigns a pre_release value" do
          @version.pre_release.should be_nil
        end

        it "assigns a build value" do
          @version.build.should eql('pre-build.11.e0f985a')
        end
      end

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

        it "doesn't assigns a pre_release value" do
          @version.pre_release.should be_nil
        end

        it "doesn't assigns a build value" do
          @version.build.should be_nil
        end
      end

      context "a five element array" do
        before(:each) { @version = subject.new([1,2,3,nil,'build.1']) }

        it "assigns a major value" do
          @version.major.should eql(1)
        end

        it "assigns a minor value" do
          @version.minor.should eql(2)
        end

        it "assigns a patch value" do
          @version.patch.should eql(3)
        end

        it "doesn't assigns a pre_release value" do
          @version.pre_release.should be_nil
        end

        it "assigns a build value" do
          @version.build.should eql('build.1')
        end
      end

      context "a four element array" do
        before(:each) { @version = subject.new([1,2,3,'alpha.1']) }

        it "assigns a major value" do
          @version.major.should eql(1)
        end

        it "assigns a minor value" do
          @version.minor.should eql(2)
        end

        it "assigns a patch value" do
          @version.patch.should eql(3)
        end

        it "assigns a pre_release value" do
          @version.pre_release.should eql('alpha.1')
        end

        it "doesn't assigns a build value" do
          @version.build.should be_nil
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

        it "doesn't assigns a pre_release value" do
          @version.pre_release.should be_nil
        end

        it "doesn't assigns a build value" do
          @version.build.should be_nil
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

        it "doesn't assigns a pre_release value" do
          @version.pre_release.should be_nil
        end

        it "doesn't assigns a build value" do
          @version.build.should be_nil
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

        it "doesn't assigns a pre_release value" do
          @version.pre_release.should be_nil
        end

        it "doesn't assigns a build value" do
          @version.build.should be_nil
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

        it "doesn't assigns a pre_release value" do
          @version.pre_release.should be_nil
        end

        it "doesn't assigns a build value" do
          @version.build.should be_nil
        end
      end
    end

    describe "::split" do
      it "returns an array containing 5 elements" do
        subject.split("1.2.0-alpha.1").should have(5).items
      end

      context "given a string only containing a major, minor and patch version" do
        it "returns an array containing 4 elements" do
          subject.split("1.2.3").should have(5).items
        end

        it "returns nil as fourth element" do
          subject.split("1.2.3")[3].should be_nil
        end

        it "returns nil as fifth element" do
          subject.split("1.2.3")[4].should be_nil
        end
      end

      context "given a string only containing a major and minor version" do
        it "returns an array containing 4 elements" do
          subject.split("1.2").should have(3).items
        end

        it "returns 0 as the third element" do
          subject.split("1.2")[2].should eql(0)
        end

        it "converts the third element to 0 if it's nil or blank" do
          subject.split("1.2.")[2].should eql(0)
        end
      end

      context "given a string with only a major version" do
        it "returns an array containing 3 elements" do
          subject.split("1").should have(3).items
        end

        it "returns 0 as the second element" do
          subject.split("1")[1].should eql(0)
        end

        it "returns 0 as the third element" do
          subject.split("1")[2].should eql(0)
        end

        it "converts the second element to 0 if it's nil or blank" do
          subject.split("1.")[1].should eql(0)
        end
      end

    context "given a string with an invalid version"
      it "raises an InvalidVersionFormat error" do
        lambda {
          subject.split("hello")
        }.should raise_error(Solve::Errors::InvalidVersionFormat)
      end
    end
  end

  describe "#pre_release?" do
    context "when a pre-release value is set" do
      subject { described_class.new("1.2.3-alpha").pre_release? }
      it { should be_true }
    end

    context "when no pre-release value is set" do
      subject { described_class.new("1.2.3").pre_release? }
      it { should be_false }
    end
  end

  describe "#zero?" do
    context "major, minor and patch are equal to 0" do
      subject { described_class.new("0.0.0").zero? }
      it { should be_true }
    end

    context "major is not equal to 0" do
      subject { described_class.new("1.0.0").zero? }
      it { should be_false }
    end

    context "minor is not equal to 0" do
      subject { described_class.new("0.1.0").zero? }
      it { should be_false }
    end

    context "patch is not equal to 0" do
      subject { described_class.new("0.0.1").zero? }
      it { should be_false }
    end
  end

  describe "#to_s" do
    subject { Solve::Version.new("1.0.0-rc.1+build.1") }

    it "returns a string containing the major.minor.patch-pre_release+build" do
      subject.to_s.should eql("1.0.0-rc.1+build.1")
    end
  end

  describe "#<=>" do
    it "compares versions" do
      versions_list = %w[
        1.0.0-0
        1.0.0-alpha
        1.0.0-alpha.1
        1.0.0-beta.2
        1.0.0-beta.11
        1.0.0-rc.1
        1.0.0-rc.1+build.1
        1.0.0
        1.0.0+0.3.7
        1.0.0+build
        1.0.0+build.2.b8f12d7
        1.0.0+build.11.e0f985a
      ]
      versions = versions_list.map { |version| Solve::Version.new(version) }

      100.times do
        shuffled_versions = versions.shuffle
        while shuffled_versions == versions
          shuffled_versions = shuffled_versions.shuffle
        end
        shuffled_versions.sort.map(&:to_s).should == versions_list
      end
    end
  end

end
