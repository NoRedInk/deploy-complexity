# frozen_string_literal: true

require 'values'

module DeployComplexity
  # Formats deploy complexity output
  class OutputFormatter <
    Value.new(
      :to,
      :base,
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

      text.compact.join("\n")
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

    def empty_commit_message; end

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
      "%s/compare/%s...%s" % [gh_url, reference(base), reference(to)]
    end
  end
end
