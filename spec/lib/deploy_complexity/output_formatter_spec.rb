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
        to_reference: "to_ref",
        migrations: [],
        elm_packages: [],
        ruby_dependencies: [],
        javascript_dependencies: []
      )
    end

    it "formats for the CLI" do
      expect(formatter.format_for_cli).to eq(
        "*Deploy tag to_commit [aaaa]*\nredeployed base_commit 0 nanoseconds"
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
        to_reference: "to_ref",
        migrations: [
          "example.com/migrate_awayyyy",
          "example.com/migrate_awayyyy_again"
        ],
        elm_packages: [
          "elm/core: 1.1.0 -> 1.2.0"
        ],
        ruby_dependencies: [
          "rspec: 3.1.0 -> 3.2.0"
        ],
        javascript_dependencies: [
          "clipboard: 0.0.1 -> 0.0.5"
        ]
      )
    end

    it "formats for the CLI" do
      expect(formatter.format_for_cli).to eq(<<-TXT.gsub(/^\s+/, "").chomp)
        *Deploy tag to_commit [aaaa]*
        0 pull requests of 0 merges, 2 commits 0 nanoseconds
        example.com/compare/base_ref...to_ref

        Migrations
        example.com/migrate_awayyyy
        example.com/migrate_awayyyy_again

        Changed Elm Packages
        elm/core: 1.1.0 -> 1.2.0

        Changed Ruby Dependencies
        rspec: 3.1.0 -> 3.2.0

        Changed JavaScript Dependencies
        clipboard: 0.0.1 -> 0.0.5

        Commits
        bbbb Do the thing
        cccc Do the thing again
      TXT
    end

    it "formats for Slack" do
      expect(formatter.format_for_slack).to eq(
        text: <<-TXT.gsub(/^\s+/, "").chomp,
        *Deploy tag to_commit [aaaa]*
        0 pull requests of 0 merges, 2 commits 0 nanoseconds
        example.com/compare/base_ref...to_ref
        TXT
        attachments: [
          {
            title: "Migrations",
            text: <<-TXT.gsub(/^\s+/, "").chomp,
              example.com/migrate_awayyyy
              example.com/migrate_awayyyy_again
            TXT
            color: "#E6E6FA"
          },
          {
            title: "Changed Elm Packages",
            text: <<-TXT.gsub(/^\s+/, "").chomp,
              elm/core: 1.1.0 -> 1.2.0
            TXT
            color: "#FFB6C1"
          },
          {
            title: "Changed Ruby Dependencies",
            text: <<-TXT.gsub(/^\s+/, "").chomp,
              rspec: 3.1.0 -> 3.2.0
            TXT
            color: "#B6FFE0"
          },
          {
            title: "Changed JavaScript Dependencies",
            text: <<-TXT.gsub(/^\s+/, "").chomp,
              clipboard: 0.0.1 -> 0.0.5
            TXT
            color: "#B6C6FF"
          },
          {
            title: "Commits",
            text: <<-TXT.gsub(/^\s+/, "").chomp,
              bbbb Do the thing
              cccc Do the thing again
            TXT
            color: "#FFCCB6"
          }
        ]
      )
    end
  end
end
