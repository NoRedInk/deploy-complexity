# frozen_string_literal: true

require 'json'

# Takes in two elm.json files and detects which packages have changed
class ChangedElmPackages
  def initialize(old:, new:)
    @old_dependencies = all_dependencies(JSON.parse(old))
    @new_dependencies = all_dependencies(JSON.parse(new))
  end

  def changes
    {
      added: added_dependencies,
      removed: removed_dependencies,
      updated: updated_dependencies
    }
  end

  private

  def all_dependencies(json)
    dependencies = json.fetch("dependencies")
    test_dependencies = json.fetch("test-dependencies")

    [
      dependencies.fetch("direct"),
      dependencies.fetch("indirect"),
      test_dependencies.fetch("direct"),
      test_dependencies.fetch("indirect")
    ].inject(&:merge)
  end

  def added_dependencies
    @new_dependencies.dup.delete_if { |package, _| @old_dependencies.key?(package) }
  end

  def removed_dependencies
    @old_dependencies.dup.delete_if { |package, _| @new_dependencies.key?(package) }
  end

  def updated_dependencies
    @new_dependencies.each_with_object({}) do |(package, new_version), changed_dependencies|
      next if @old_dependencies[package].nil?
      next if @old_dependencies[package] == new_version

      changed_dependencies[package] = {
        old: @old_dependencies[package],
        new: new_version
      }
    end
  end
end
