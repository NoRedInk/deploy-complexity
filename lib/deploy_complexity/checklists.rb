# frozen_string_literal: true

# define a bunch of checklist items that can be added to PRs automatically
module Checklists
  # all checklists should inherit from this class. It makes sure that the
  # checklist output is consistent in the PR so we don't get duplicates.
  class Checklist
    def id
      "checklist:#{self.class.name}"
    end

    def title
      "**#{human_name} Checklist**"
    end

    def to_s
      self.class.name
    end

    def for_pr_body
      "\n\n<!-- #{id} -->\n#{title}\n\n#{checklist}"
    end
  end

  # Github-flavored Markdown doesn't wrap line breaks, so we need to disable
  # line length checks for now.
  # rubocop:disable Metrics/LineLength

  class RubyFactoriesChecklist < Checklist
    def human_name
      "Ruby Factories"
    end

    def checklist
      '
- [ ] RSpec: use [traits](https://robots.thoughtbot.com/remove-duplication-with-factorygirls-traits) to make the default case fast
      '.strip
    end

    def relevant_for(files)
      files.select { |file| file.start_with?("spec/factories") }
    end
  end

  class RoutesChecklist < Checklist
    def human_name
      "Routes"
    end

    def checklist
      '
- [ ] Retired routes are redirected
      '.strip
    end

    def relevant_for(files)
      files.select { |file| file == "config/routes.rb" }
    end
  end

  class ResqueChecklist < Checklist
    def human_name
      "Resque"
    end

    def checklist
      '
- [ ] Resque jobs should not be allowed to change their `.perform` signature. Rather, create a new resque job and retire the old one post-deploy after the queue is empty
      '.strip
    end

    def relevant_for(files)
      files.select { |file| file.start_with? "app/jobs" }
    end
  end

  # all done!
  # rubocop:enable Style/Documentation
  # rubocop:enable Metrics/LineLength

  # Check for checklists, given a list of checkers
  class Checker
    def initialize(checklists)
      @checklists = checklists
    end

    def for_files(files)
      @checklists
        .map(&:new)
        .map { |checker| [checker, checker.relevant_for(files)] }
        .to_h
        .reject { |_, values| values.empty? }
    end
  end

  module_function

  def checklists
    [
      RubyFactoriesChecklist,
      RoutesChecklist,
      ResqueChecklist,
    ].freeze
  end

  def for_files(checklists, files)
    puts "Applying %s" % [checklists.join(",").gsub(/Checklists::/,'')]
    Checker.new(checklists).for_files(files)
  end
end
