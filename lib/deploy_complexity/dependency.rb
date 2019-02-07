# frozen_string_literal: true

require 'values'

module DeployComplexity
  # Represents a potential change in a package version for a dependency file
  class Dependency < Value.new(:package, :current, :previous, :file)
    def change
      if current.nil?
        :removed
      elsif previous.nil?
        :added
      elsif current != previous
        :updated
      else
        :unchanged
      end
    end

    def unchanged?
      change == :unchanged
    end

    def to_s
      case change
      when :removed
        "Removed %s (%s)" % [package, file]
      when :added
        "Added %s: %s (%s)" % [package, current, file]
      when :updated
        "Updated %s: %s -> %s (%s)" % [package, previous, current, file]
      else
        "Unchanged %s (%s)" % [package, file]
      end
    end
  end
end
