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
  end
end
