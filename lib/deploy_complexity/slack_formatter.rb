# frozen_string_literal: true

require 'values'

# Formats deploy complexity output for slack
class SlackFormatter <
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

  COMPARE_FORMAT = "%s/compare/%s...%s"

  def format
    text = [header]

    if commits.empty?
      text << "redeployed %s %s" % [base, time_delta]
    else
      text << summary_stats
      text << compare_url
      text << shortstats
    end

    text.compact.join("\n")
  end

  private

  attr_reader :deploy_data

  def header
    "*Deploy tag #{to} [#{revision}]*"
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
    COMPARE_FORMAT % [gh_url, reference(base), reference(to)]
  end
end
