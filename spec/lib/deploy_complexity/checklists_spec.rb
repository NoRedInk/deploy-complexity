# frozen_string_literal: true

require 'spec_helper'
require 'deploy_complexity/checklists'

describe Checklists do
  before(:all) do
    class TestChecklist < Checklists::Checklist
      def human_name
        "Human Name"
      end

      def checklist
        "CHECKLIST"
      end

      def relevant_for(files)
        files.reject { |f| f == "no" }
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
        expect(checker.for_files(["foo"])).to include TestChecklist
      end

      it "does not have any checklists at all for no file" do
        expect(checker.for_files([])).to eq({})
      end

      it "does not have irrelevant checklists" do
        expect(checker.for_files(["no"])).to_not include TestChecklist
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

  describe 'Checklists' do
    define :be_relevant_for do |file|
      match { |actual| actual.relevant_for([file]).member?(file) }
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

    describe 'ElmFactoriesChecklist' do
      subject { Checklists::ElmFactoriesChecklist.new }

      it_behaves_like "a checklist class"

      it "should be relevant for elm specs" do
        expect(subject).to be_relevant_for("ui/tests/SomeNeatSpec.elm")
      end
    end

    describe 'CapistranoChecklist' do
      subject { Checklists::CapistranoChecklist.new }

      it_behaves_like "a checklist class"

      it "should be relevant for files under lib/capistrano/" do
        expect(subject).to be_relevant_for("lib/capistrano/tasks/foobar.rake")
      end

      it "should be relevant for the Capfile" do
        expect(subject).to be_relevant_for("Capfile")
      end

      it "should be relevant for the Gemfile" do
        expect(subject).to be_relevant_for("Gemfile")
      end

      it "should be relevant for files under lib/deploy/" do
        expect(subject).to be_relevant_for("lib/deploy/foobar.rb")
      end

      it "should be relevant for files with cap as a word in their name" do
        expect(subject).to be_relevant_for("script/a_cap_ital_idea.sh")
      end

      it "should not be relevant for files with 'cap' as part of another word" do
        expect(subject).to_not be_relevant_for("a_capital_idea.rb")
      end
    end

    describe 'OpsWorksChecklist' do
      subject { Checklists::OpsWorksChecklist.new }

      it_behaves_like "a checklist class"

      it "should be relevant for any file with opsworks in the name" do
        expect(subject).to be_relevant_for("script/opsworks-foo.rb")
      end

      it "should be relevant for config/deploy.rb" do
        expect(subject).to be_relevant_for("config/deploy.rb")
      end

      it "should be relevant for files under deploy/" do
        expect(subject).to be_relevant_for("deploy/before_migrate.rb")
      end

      it "should be relevant for files under lib/deploy/" do
        expect(subject).to be_relevant_for("lib/deploy/foobar.rb")
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

    describe 'MigrationChecklist' do
      subject { Checklists::MigrationChecklist.new }

      it_behaves_like "a checklist class"

      it "should be relevant for migrations" do
        expect(subject).to be_relevant_for("db/migrate/hey_whats_up.rb")
      end
    end
  end
end
