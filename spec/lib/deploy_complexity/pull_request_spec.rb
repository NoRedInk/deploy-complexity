# frozen_string_literal: true

require 'deploy_complexity/pull_request'

describe PullRequest do
  let(:prs) { [Struct.new(:body, :number).new(body, number)] }
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
