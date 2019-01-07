# frozen_string_literal: true

require 'values'

module DeployComplexity
  Attachment = Value.new(:title, :text, :color)

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
      :gh_url,
      :migrations,
      :elm_packages,
      :ruby_dependencies,
      :javascript_dependencies
    )

    def format_for_slack
      {
        text: text.compact.join("\n"),
        attachments: attachments.map { |a| format_attachment_for_slack(a) }
      }
    end

    def format_for_cli
      output = text.compact.join("\n")

      added_attachments = attachments

      return output unless added_attachments.any?

      output + "\n" +
        added_attachments.map { |a| format_attachment_for_cli(a) }.join("\n")
    end

    private

    attr_reader :deploy_data

    def text
      text = []

      text << header

      if commits.empty?
        text << empty_commit_message
      else
        text << summary_stats
        text << compare_url
        text << shortstats
      end

      text
    end

    def attachments
      return [] if commits.empty?

      attachments = []

      attachments << migration_attachment if migrations.any?
      attachments << elm_package_attachment if elm_packages.any?
      attachments << ruby_dependency_attachment if ruby_dependencies.any?
      attachments << javascript_dependency_attachment if javascript_dependencies.any?

      attachments
    end

    def format_attachment_for_slack(attachment)
      attachment.to_h
    end

    def format_attachment_for_cli(attachment)
      attachment.title + "\n" + attachment.text
    end

    def empty_commit_message
      "redeployed %s %s" % [base, time_delta]
    end

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
      "%s/compare/%s...%s" % [gh_url, base_reference, to_reference]
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
  end
end
