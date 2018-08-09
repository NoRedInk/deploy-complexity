# frozen_string_literal: true

# define a bunch of checklist items that can be added to PRs automatically
module Checklists
  # all checklists should inherit from this class. It makes sure that the
  # checklist output is consistent in the PR so we don't get duplicates.
  class Checklist
    def id
      "checklist:#{self.class.name}"
    end

    def to_s
      self.class.name
    end

    def for_pr_body
      "\n\n<!-- #{id} -->\n#{checklist}"
    end
  end

  # all these subclasses should be self-descriptive from their classnames, so go
  # away rubocop.
  # rubocop:disable Style/Documentation

  # Github-flavored Markdown doesn't wrap line breaks, so we need to disable
  # line length checks for now.
  # rubocop:disable Metrics/LineLength

  class RubyFactoriesChecklist < Checklist
    def checklist
      '
**Ruby Factories Checklist**

- [ ] RSpec: use [traits](https://robots.thoughtbot.com/remove-duplication-with-factorygirls-traits) to make the default case fast
      '.strip
    end

    def relevant_for?(files)
      files.any? { |file| file.starts_with?("spec/factories") }
    end
  end

  class ElmFactoriesChecklist < Checklist
    def checklist
      '
**Elm Factories Checklist**

- [ ] Elm fuzz tests: use [shortList](https://github.com/NoRedInk/NoRedInk/blob/72626abf20e44eb339dd60ebb716e9447910127f/ui/tests/SpecHelpers.elm#L59) when a list fuzzer is generating too many cases
      '.strip
    end

    def relevant_for?(files)
      files.any? { |file| file.starts_with?("ui/tests/") }
    end
  end

  class CapistranoChecklist < Checklist
    def checklist
      "
**Capistrano Checklist**

The process for testing capistrano is to deploy the capistrano changes branch to staging prior to merging to master and verify the deploy doesn't explode.

- [ ] Make a branch with capistrano changes
- [ ] Wait for free time to test staging
- [ ] Reset/deploy that branch to staging using the normal jenkins deploy process
- [ ] Verify the deploy passes
  - If it doesn't, fix the branch and redeploy until it works
  - [ ] If it does, reset back to origin/master and request review of the PR
      ".strip
    end

    def relevant_for?(files)
      files.any? do |file|
        file == "Capfile" \
          || file.starts_with?("lib/capistrano/") \
          || file.starts_with?("lib/deploy/") \
          || file.starts_with?("config/deploy") \
          || file.match('.*[\b_\./]cap[\b_\./].*').present?
      end
    end
  end

  class OpsWorksChecklist < Checklist
    def checklist
      "
**OpsWorks Checklist**

- [ ] Change the source code branch for staging to the branch being tested in the opsworks UI
- [ ] Create a brand new instance in the layer ([see instructions](https://github.com/NoRedInk/wiki/blob/master/ops-playbook/ops-scripts.md#synchronize_stackrb.))
- [ ] Turn it on
- [ ] Verify that the instances passes setup to online and doesn't fail
      ".strip
    end

    def relevant_for?(files)
      files.any? do |file|
        file.starts_with?("config/deploy") \
          || file.include?("opsworks") \
          || file.starts_with?("deploy/") \
          || file.starts_with?("lib/deploy/")
      end
    end
  end

  class RoutesChecklist < Checklist
    def checklist
      '
**Routes Checklist**

- [ ] Retired routes are redirected
      '.strip
    end

    def relevant_for?(files)
      files.member? "config/routes.rb"
    end
  end

  class ResqueChecklist < Checklist
    def checklist
      '
**Resque Checklist**

- [ ] Resque jobs should not be allowed to change their `.perform` signature. Rather, create a new resque job and retire the old one post-deploy after the queue is empty
      '.strip
    end

    def relevant_for?(files)
      files.any? { |file| file.starts_with? "app/jobs" }
    end
  end

  class MigrationChecklist < Checklist
    def checklist
      '
**Migrations Checklist**

- [ ] If there are any potential [Slow Migrations](https://github.com/NoRedInk/wiki/blob/master/Slow-Migrations.md), make sure that:
  - [ ] They are in separate PRs so each can be run independently
  - [ ] There is a deployment plan where the resulting code on prod will support the db schema both before and after the migration
- [ ] If migrations include dropping a column, modifying a column, or adding a non-nullable column, ensure the previously deployed model is prepared to handle both the previous schema and the new schema. ([See "Rails Migrations with Zero Downtime](https://blog.codeship.com/rails-migrations-zero-downtime/)")
      '.strip
    end

    def relevant_for?(files)
      files.any? { |file| file.starts_with? "db/migrate/" }
    end
  end

  # all done!
  # rubocop:enable Style/Documentation
  # rubocop:enable Metrics/LineLength

  module_function

  def get_files_changed(ref1, ref2)
    files = `git diff --name-only '#{ref1}...#{ref2}'`
    files.split("\n")
  end

  def checklists_for_files(files)
    Checklists::Checklist
      .subclasses
      .map(&:new)
      .select { |checker| checker.relevant_for?(files) }
  end
end
