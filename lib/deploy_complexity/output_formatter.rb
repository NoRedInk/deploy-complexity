# frozen_string_literal: true

require 'values'
require 'deploy_complexity/github'

module DeployComplexity
  Attachment = Value.new(:title, :text, :color)

  # Parent class for formatting deploy complexity output
  # Child classes (slack, cli) should implement #format and #format_attachment
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
      :dirstat,
      :stat,
      :time_delta,
      :github,
      :migrations,
      :elm_packages,
      :ruby_dependencies,
      :javascript_dependencies
    )

    # This should be implemented in child classes and be the final output
    def format; end

    private

    attr_reader :deploy_data

    # This should be implemented in child classes
    def format_attachment(_attachment); end

    def text
      text = []

      text << header

      if commits.empty?
        text << empty_commit_message
      else
        text << summary_stats
        text << github.compare(base_reference, to_reference)
        text << shortstats
      end

      text.compact.join("\n")
    end

    def attachments
      return [] if commits.empty?

      attachments = []

      attachments << migration_attachment if migrations.any?
      attachments << elm_package_attachment if elm_packages.any?
      attachments << ruby_dependency_attachment if ruby_dependencies.any?
      attachments << javascript_dependency_attachment if javascript_dependencies.any?
      # FIXME: there may be commits in the deploy unassociated with a PR
      content_attachment = pull_requests.any? ? pull_request_attachment : commits_attachment
      attachments << content_attachment
      attachments << dirstat_attachment if dirstat
      attachments << stat_attachment if stat

      attachments
    end

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

    def migration_attachment
      Attachment.with(
        title: "Migrations",
        text: migrations.join("\n"),
        color: "#E6E6FA"
      )
    end

    def elm_package_attachment
      Attachment.with(
        title: "Changed Elm Packages",
        text: elm_packages.join("\n"),
        color: "#FFB6C1"
      )
    end

    def ruby_dependency_attachment
      Attachment.with(
        title: "Changed Ruby Dependencies",
        text: ruby_dependencies.join("\n"),
        color: "#B6FFE0"
      )
    end

    def javascript_dependency_attachment
      Attachment.with(
        title: "Changed JavaScript Dependencies",
        text: javascript_dependencies.join("\n"),
        color: "#B6C6FF"
      )
    end

    def pull_request_attachment
      Attachment.with(
        title: "Pull Requests",
        text: pull_requests.map do |pr|
          url = github.pull_request(pr.fetch(:pr_number))
          "#{url} #{pr.fetch(:joiner)} #{pr.fetch(:name)}"
        end.join("\n"),
        color: "#FFCCB6"
      )
    end

    def commits_attachment
      Attachment.with(
        title: "Commits",
        text: commits.join("\n"),
        color: "#FFCCB6"
      )
    end

    def stat_attachment
      Attachment.with(
        title: "Stats",
        text: stat,
        color: "#D6B6FF"
      )
    end

    def dirstat_attachment
      Attachment.with(
        title: "Dirstats",
        text: dirstat,
        color: "#B6D8FF"
      )
    end
  end
end
