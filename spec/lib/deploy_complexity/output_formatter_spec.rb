# frozen_string_literal: true

require 'deploy_complexity/output_formatter'

describe DeployComplexity::OutputFormatter do
  context "with no commits" do
    let(:formatter) do
      DeployComplexity::OutputFormatter.with(
        to: "to_commit",
        base: "base_commit",
        revision: "aaaa",
        commits: [],
        pull_requests: [],
        merges: [],
        shortstat: "",
        time_delta: "0 nanoseconds",
        gh_url: "example.com",
        base_reference: "base_ref",
        to_reference: "to_ref"
      )
    end

    it "formats for the CLI" do
      expect(formatter.format_for_cli).to eq(
        "Deploy tag to_commit [aaaa]\nredeployed base_commit 0 nanoseconds"
      )
    end

    it "formats for Slack" do
      expect(formatter.format_for_slack).to eq(
        text: "*Deploy tag to_commit [aaaa]*\nredeployed base_commit 0 nanoseconds",
        attachments: []
      )
    end
  end

  context "with commits" do
    let(:formatter) do
      DeployComplexity::OutputFormatter.with(
        to: "to_commit",
        base: "base_commit",
        revision: "aaaa",
        commits: [
          "bbbb Do the thing",
          "cccc Do the thing again"
        ],
        pull_requests: [],
        merges: [],
        shortstat: "",
        time_delta: "0 nanoseconds",
        gh_url: "example.com",
        base_reference: "base_ref",
        to_reference: "to_ref"
      )
    end

    it "formats for the CLI" do
      expect(formatter.format_for_cli).to eq(<<-TXT.gsub(/^\s+/, "").chomp)
        Deploy tag to_commit [aaaa]
        0 pull requests of 0 merges, 2 commits 0 nanoseconds
        example.com/compare/base_ref...to_ref
      TXT
    end

    it "formats for Slack" do
      expect(formatter.format_for_slack).to eq(
        text: <<-TXT.gsub(/^\s+/, "").chomp,
        *Deploy tag to_commit [aaaa]*
        0 pull requests of 0 merges, 2 commits 0 nanoseconds
        example.com/compare/base_ref...to_ref
        TXT
        attachments: []
      )
    end
  end
end
