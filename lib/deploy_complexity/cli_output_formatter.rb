# frozen_string_literal: true

require "deploy_complexity/output_formatter"

module DeployComplexity
  # Formats deploy complexity output for cli
  class CliOutputFormatter < OutputFormatter
    def format
      output = text

      added_attachments = attachments

      return output unless added_attachments.any?

      output + "\n\n" +
        added_attachments.map { |a| format_attachment(a) }.join("\n\n")
    end

    private

    def format_attachment(attachment)
      attachment.title + "\n" + attachment.text
    end
  end
end
