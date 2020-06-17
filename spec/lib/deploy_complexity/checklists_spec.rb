# frozen_string_literal: true

require 'spec_helper'
require 'deploy_complexity/checklists'

describe Checklists do
  # represents a Git::FileDiff
  def diff(path, patch: "")
    double(path: path, patch: patch)
  end

  class TestChecklist < Checklists::Checklist
    def human_name
      "Human Name"
    end

    def checklist
      "CHECKLIST"
    end

    def relevant_for(files)
      files.reject { |f| f.path == "no" }
    end
  end

  class PatchChecklist < Checklists::Checklist
    def human_name
      "patches"
    end

    def checklist
      "- [] did you mean to change a dependency"
    end

    def relevant_for(changes)
      changes.select do |file|
        insertions = file.patch.split(/\n/).select { |x| x.match(/^\+/) }
        insertions.any? { |x| x.match(/add_dependency/) }
      end
    end
  end

  shared_examples_for 'a checklist class' do
    it "should give back a string for checklist" do
      expect(subject).to respond_to :checklist
      expect(subject.checklist).to be_a String
    end

    it "should give back a string for id" do
      expect(subject).to respond_to :id
      expect(subject.id).to be_a String
    end

    it "should give back a string for a human_name" do
      expect(subject).to respond_to :human_name
      expect(subject.id).to be_a String
    end

    it "should respond to relevant_for" do
      expect(subject).to respond_to :relevant_for
    end

    it "should not be relevant for an empty list of files" do
      expect(subject.relevant_for([])).to eq []
    end
  end

  describe Checklists::Checker do
    let(:checklists) { [TestChecklist] }
    let(:checker) { Checklists::Checker.new(checklists) }

    describe 'for_files' do
      it "has the relevant checklists" do
        expect(checker.for_files([diff("foo")])).to include TestChecklist
      end

      it "does not have any checklists at all for no file" do
        expect(checker.for_files([])).to eq({})
      end

      it "does not have irrelevant checklists" do
        expect(checker.for_files([diff("no")])).to_not include TestChecklist
      end
    end
  end

  describe 'Checklist' do
    subject { TestChecklist.new }

    it_behaves_like "a checklist class"

    describe "id" do
      it "has the class name" do
        expect(subject.id).to eq "checklist:TestChecklist"
      end
    end

    describe "for_pr_body" do
      it "has the ID" do
        expect(subject.for_pr_body).to include(subject.id)
      end

      it "has the checklist" do
        expect(subject.for_pr_body).to include(subject.checklist)
      end
    end
  end

  describe PatchChecklist do
    it_behaves_like "a checklist class"

    it 'matches on a diff insertion' do
      patch = <<DIFF
diff --git a/deploy-complexity.gemspec b/deploy-complexity.gemspec
index 1f82fcb..b2e4ffb 100644
--- a/deploy-complexity.gemspec
+++ b/deploy-complexity.gemspec
@@ -26,10 +26,10 @@ Gem::Specification.new do |spec|
   spec.add_development_dependency "bundler", "~> 2.1"
   spec.add_development_dependency "rake", "~> 13.0"

+  spec.add_dependency "git", "~> 1.7.0"
   spec.add_dependency "octokit", "~> 4.0"
   spec.add_dependency "slack-notifier", "~> 2.3.2"
   spec.add_dependency "values", "~> 1.8.0"
-  spec.add_dependency "git", "~> 1.7.0"

   spec.required_ruby_version = ">= 2.5"
 end
DIFF

      spec_add = diff('deploy-complexity.gemspec', patch: patch)
      spec_removal = diff('foo', patch: "\n-  spec.add_dependency\n")
      changes = [spec_add, spec_removal]
      relevant = PatchChecklist.new.relevant_for(changes)
      expect(relevant).to match_array([spec_add])
    end
  end

  describe 'Checklists' do
    define :be_relevant_for do |file|
      match do |actual|
        actual.relevant_for([diff(file)]).map(&:path).member?(file)
      end
    end

    describe 'RubyFactoriesChecklist' do
      subject { Checklists::RubyFactoriesChecklist.new }

      it_behaves_like "a checklist class"

      it "should be relevant for ruby factories" do
        expect(subject).to be_relevant_for("spec/factories/users.rb")
      end

      it "should be relevant for ruby factory tests" do
        expect(subject).to be_relevant_for("spec/factories_spec.rb")
      end
    end

    describe 'RoutesChecklist' do
      subject { Checklists::RoutesChecklist.new }

      it_behaves_like "a checklist class"

      it "should be relevant for the routes file" do
        expect(subject).to be_relevant_for("config/routes.rb")
      end
    end

    describe 'ResqueChecklist' do
      subject { Checklists::ResqueChecklist.new }

      it_behaves_like "a checklist class"

      it "should be relevant for resque tasks" do
        expect(subject).to be_relevant_for("app/jobs/foobar_job.rb")
      end
    end
  end
end
