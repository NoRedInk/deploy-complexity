# frozen_string_literal: true

require "deploy_complexity/output_formatter"

module DeployComplexity
  # Formats deploy complexity output for slack
  class SlackOutputFormatter < OutputFormatter
    def format
      {
        text: text,
        attachments: attachments.map { |a| format_attachment(a) }
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

    # Override parent by fancy formatting links
    def pull_request_attachment
      Attachment.with(
        title: "Pull Requests",
        text: pull_requests.map do |pr|
          url = "#{pr.fetch(:gh_url)}/pull/#{pr.fetch(:pr_number)}"
          "<#{url}|#{pr.fetch(:pr_number)}> - #{pr.fetch(:name)}"
        end.join("\n"),
        color: "#FFCCB6"
      )
    end
  end
end
