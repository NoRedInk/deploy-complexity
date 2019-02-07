# frozen_string_literal: true

require "deploy_complexity/output_formatter"
require "deploy_complexity/github"

module DeployComplexity
  # Formats deploy complexity output for slack
  class SlackOutputFormatter < OutputFormatter
    def format
      {
        text: text,
        attachments: attachments.map { |a| format_attachment(a) }
      }
    rescue StandardError => e
      {
        text: "Something went wrong formatting output",
        attachments: [
          {
            title: e.message,
            text: e.backtrace.join("\n")
          }
        ]
      }
    end

    private

    def format_attachment(attachment)
      attachment.to_h
    end

    # Override header by making it bold
    def header
      "*#{super}*"
    end

    def compare_link
      "<%s|%s...%s>" % [super, base_reference, to_reference]
    end

    def migration_attachment
      links = migrations.map do |migration|
        "<%s|%s>" % [github.blob(revision, migration), migration]
      end
      Attachment.with(
        title: "Migrations",
        text: links.join("\n"),
        color: "#E6E6FA"
      )
    end

    # Override parent by fancy formatting links
    def pull_request_attachment
      Attachment.with(
        title: "Pull Requests",
        text: pull_requests.map do |pr|
          url = github.pull_request(pr.fetch(:pr_number))
          "<#{url}|#{pr.fetch(:pr_number)}> - #{pr.fetch(:name)}"
        end.join("\n"),
        color: "#FFCCB6"
      )
    end
  end
end
