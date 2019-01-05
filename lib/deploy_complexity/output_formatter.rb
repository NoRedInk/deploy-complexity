# frozen_string_literal: true

require 'values'

module DeployComplexity
  # Formats deploy complexity output
  class OutputFormatter <
    Value.new(
      :to,
      :base,
      :base_reference,
      :to_reference,
      :revision,
      :commits,
      :pull_requests,
      :merges,
      :shortstat,
      :time_delta,
      :gh_url
    )

    def format_for_slack
      text = []

      text << "*#{header}*"

      if commits.empty?
        text << empty_commit_message
      else
        text << summary_stats
        text << compare_url
        text << shortstats
      end

      {
        text: text.compact.join("\n"),
        attachments: []
      }
    end

    def format_for_cli
      text = []

      text << header

      if commits.empty?
        text << empty_commit_message
      else
        text << summary_stats
        text << compare_url
        text << shortstats
      end

      text.compact.join("\n")
    end

    private

    attr_reader :deploy_data

    def empty_commit_message
      "redeployed %s %s" % [base, time_delta]
    end

    def header
      "Deploy tag #{to} [#{revision}]"
    end

    def summary_stats
      "%d pull requests of %d merges, %d commits %s" %
        [pull_requests.count, merges.count, commits.count, time_delta]
    end

    def shortstats
      return if shortstat.empty?

      shortstat.first.strip
    end

    def compare_url
      "%s/compare/%s...%s" % [gh_url, base_reference, to_reference]
    end
  end
end
