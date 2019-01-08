# frozen_string_literal: true

require 'deploy_complexity/cli_output_formatter'

describe DeployComplexity::CliOutputFormatter do
  context "with no commits" do
    let(:formatter) do
      DeployComplexity::CliOutputFormatter.with(
        to: "to_commit",
        base: "base_commit",
        revision: "aaaa",
        commits: [],
        pull_requests: [],
        merges: [],
        shortstat: "",
        stat: nil,
        dirstat: nil,
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
      expect(formatter.format).to eq(
        "Deploy tag to_commit [aaaa]\nredeployed base_commit 0 nanoseconds"
      )
    end
  end

  context "with commits" do
    let(:formatter) do
      DeployComplexity::CliOutputFormatter.with(
        to: "to_commit",
        base: "base_commit",
        revision: "aaaa",
        commits: [
          "bbbb Do the thing",
          "cccc Do the thing again"
        ],
        pull_requests: [
          {
            gh_url: "example.com",
            pr_number: "1",
            joiner: "-",
            name: "add-more-cats"
          }
        ],
        merges: [],
        shortstat: "",
        stat: nil,
        dirstat: nil,
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
      expect(formatter.format).to eq(<<-TXT.gsub(/^ +/, "").chomp)
        Deploy tag to_commit [aaaa]
        1 pull requests of 0 merges, 2 commits 0 nanoseconds
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

        Pull Requests
        <example.com/pull/1|1> - add-more-cats
      TXT
    end
  end
end
