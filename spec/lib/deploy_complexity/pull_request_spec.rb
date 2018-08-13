# frozen_string_literal: true

require 'deploy_complexity/pull_request'

describe PullRequest do
  let(:prs) { [Struct.new(:body, :number).new(body, number)] }
  let(:body) { "" }
  let(:number) { 42 }
  let(:client) { instance_double(Octokit::Client) }
  let(:checklist) { Struct.new(:for_pr_body, :id).new("CHECKLIST", "ID") }

  before do
    # set up client double
    allow(client).to receive(:pull_requests).and_return(prs)
    allow(client).to receive(:update_issue)
    allow(client).to receive(:add_comment)
  end

  let(:org) { "org" }
  let(:repo) { "repo" }
  let(:branch) { "branch" }
  subject { PullRequest.new(client, org, repo, branch) }

  context 'when the branch does not have a PR' do
    let(:prs) { [] }

    it "should not be present" do
      expect(subject).to_not be_present
    end

    it "cannot update with checklists" do
      expect { subject.update_with_checklists([checklist]) }.to_not raise_exception
    end

    it "cannot get base" do
      expect { subject.base }.to_not raise_exception
      expect(subject.base).to be_nil
    end

    it "cannot get head" do
      expect { subject.head }.to_not raise_exception
      expect(subject.head).to be_nil
    end
  end

  describe 'string form' do
    it 'contains the org' do
      expect(subject.to_s).to include org
    end

    it 'contains the repo' do
      expect(subject.to_s).to include repo
    end

    it 'contains the PR number' do
      expect(subject.to_s).to include number.to_s
    end
  end

  describe 'update_with_checklists' do
    context "when the checklist isn't present" do
      let(:body) { "" }

      it "should add the checklist" do
        expect(subject.update_with_checklists([checklist])).to include(checklist)
      end
    end

    context "when the checklist ID is present" do
      let(:body) { checklist.id }

      it "should not add the checklist again" do
        expect(subject.update_with_checklists([checklist])).to eq []
      end
    end
  end
end
