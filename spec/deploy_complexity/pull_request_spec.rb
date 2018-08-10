# frozen_string_literal: true

require 'spec_helper'
require 'deploy_complexity/pull_request'

describe 'checklists' do
  # rubocop:disable RSpec/BeforeAfterAll
  # before(:all) do
  #   class TestChecklist < Checklists::Checklist
  #     def checklist
  #       "CHECKLIST"
  #     end
  #   end
  # end

  # after(:all) { Rake::Task.clear }

  # describe 'Checklist' do
  #   subject { TestChecklist.new }

  #   describe "id" do
  #     it "has the class name" do
  #       expect(subject.id).to eq "checklist:TestChecklist"
  #     end
  #   end

  #   describe "for_pr_body" do
  #     it "has the ID" do
  #       expect(subject.for_pr_body).to include(subject.id)
  #     end

  #     it "has the checklist" do
  #       expect(subject.for_pr_body).to include(subject.checklist)
  #     end
  #   end
  # end

  # describe 'Checklists' do
  #   shared_examples_for 'a checklist class' do
  #     it "should give back a string for checklist" do
  #       expect(subject).to respond_to :checklist
  #       expect(subject.checklist).to be_a String
  #     end

  #     it "should give back a string for id" do
  #       expect(subject).to respond_to :id
  #       expect(subject.id).to be_a String
  #     end

  #     it "should respond to relevant_for?" do
  #       expect(subject).to respond_to :relevant_for?
  #     end

  #     it "should not trigger for no files" do
  #       expect(subject.relevant_for? []).to be false
  #     end
  #   end

  #   it "there should be no duplicate IDs" do
  #     ids = Checklists::Checklist.subclasses.map { |cls| cls.new.id }

  #     expect(ids).to eq ids.uniq
  #   end

  #   describe 'RubyFactoriesChecklist' do
  #     subject { Checklists::RubyFactoriesChecklist.new }

  #     it_behaves_like "a checklist class"

  #     it "should be relevant for ruby factories" do
  #       expect(subject).to be_relevant_for(["spec/factories/users.rb"])
  #     end

  #     it "should be relevant for ruby factory tests" do
  #       expect(subject).to be_relevant_for(["spec/factories_spec.rb"])
  #     end
  #   end

  #   describe 'ElmFactoriesChecklist' do
  #     subject { Checklists::ElmFactoriesChecklist.new }

  #     it_behaves_like "a checklist class"

  #     it "should be relevant for elm specs" do
  #       expect(subject).to be_relevant_for(["ui/tests/SomeNeatSpec.elm"])
  #     end
  #   end

  #   describe 'CapistranoChecklist' do
  #     subject { Checklists::CapistranoChecklist.new }

  #     it_behaves_like "a checklist class"

  #     it "should be relevant for files under lib/capistrano/" do
  #       expect(subject).to be_relevant_for(["lib/capistrano/tasks/foobar.rake"])
  #     end

  #     it "should be relevant for the Capfile" do
  #       expect(subject).to be_relevant_for(["Capfile"])
  #     end

  #     it "should be relevant for files under lib/deploy/" do
  #       expect(subject).to be_relevant_for(["lib/deploy/foobar.rb"])
  #     end

  #     it "should be relevant for files with cap as a word in their name" do
  #       expect(subject).to be_relevant_for(["script/a_cap_ital_idea.sh"])
  #     end

  #     it "should not be relevant for files with 'cap' as part of another word" do
  #       expect(subject).to_not be_relevant_for(["a_capital_idea.rb"])
  #     end
  #   end

  #   describe 'OpsWorksChecklist' do
  #     subject { Checklists::OpsWorksChecklist.new }

  #     it_behaves_like "a checklist class"

  #     it "should be relevant for any file with opsworks in the name" do
  #       expect(subject).to be_relevant_for(["script/opsworks-foo.rb"])
  #     end

  #     it "should be relevant for config/deploy.rb" do
  #       expect(subject).to be_relevant_for(["config/deploy.rb"])
  #     end

  #     it "should be relevant for files under deploy/" do
  #       expect(subject).to be_relevant_for(["deploy/before_migrate.rb"])
  #     end

  #     it "should be relevant for files under lib/deploy/" do
  #       expect(subject).to be_relevant_for(["lib/deploy/foobar.rb"])
  #     end
  #   end

  #   describe 'RoutesChecklist' do
  #     subject { Checklists::RoutesChecklist.new }

  #     it_behaves_like "a checklist class"

  #     it "should be relevant for the routes file" do
  #       expect(subject).to be_relevant_for(["config/routes.rb"])
  #     end
  #   end

  #   describe 'ResqueChecklist' do
  #     subject { Checklists::ResqueChecklist.new }

  #     it_behaves_like "a checklist class"

  #     it "should be relevant for resque tasks" do
  #       expect(subject).to be_relevant_for(["app/jobs/foobar_job.rb"])
  #     end
  #   end

  #   describe 'MigrationChecklist' do
  #     subject { Checklists::MigrationChecklist.new }

  #     it_behaves_like "a checklist class"

  #     it "should be relevant for migrations" do
  #       expect(subject).to be_relevant_for(["db/migrate/hey_whats_up.rb"])
  #     end
  #   end
  # end

  describe 'PullRequest' do
    let(:prs) { [ Struct.new(:body, :number).new(body, number) ] }
    let(:body) { "" }
    let(:number) { 42 }
    let(:client) { instance_double(Octokit::Client) }
    let(:checklist) { Struct.new(:for_pr_body, :id).new("CHECKLIST", "ID") }

    before do
      expect(Octokit::Client).to receive(:new).and_return(client)

      # set up client double
      allow(client).to receive(:pull_requests).and_return(prs)
      allow(client).to receive(:update_issue)
    end

    subject { PullRequest.new("fake-branch-name", "FAKE", "org", "repo") }

    context 'when the PR is not found' do
      let(:prs) { [] }

      it "should not be present" do
        expect(subject).to_not be_present
      end

      it "cannot add comment" do
        expect { subject.add_comment("some comment") }.to_not raise_exception
      end

      it "cannot append checklists" do
        expect { subject.append_checklists([checklist]) }.to_not raise_exception
      end

      it "cannot add checklist comment" do
        expect { subject.add_checklist_comment([checklist]) }.to_not raise_exception
      end

      it "cannot get base" do
        expect { subject.base }.to_not raise_exception
      end

      it "cannot get head" do
        expect { subject.head }.to_not raise_exception
      end

      it "cannot get number" do
        expect { subject.number }.to_not raise_exception
      end
    end

    describe 'append_checklists' do
      context "when the checklist isn't present" do
        let(:body) { "" }

        it "should add the checklist" do
          expect(subject.append_checklists([checklist])).to include(checklist)
        end
      end

      context "when the checklist ID is present" do
        let(:body) { checklist.id }

        it "should not add the checklist again" do
          expect(subject.append_checklists([checklist])).to eq []
        end
      end
    end
  end
end
