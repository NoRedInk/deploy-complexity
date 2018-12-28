# frozen_string_literal: true

# Detects changes in two package-lock.json files
class ChangedJavascriptPackages
  def initialize(old:, new:)
    @old_dependencies = all_dependencies(JSON.parse(old))
    @new_dependencies = all_dependencies(JSON.parse(new))
  end

  def changes
    [
      format_dependencies("Added", added_dependencies),
      format_dependencies("Removed", removed_dependencies),
      format_updated_dependencies(updated_dependencies)
    ].flatten
  end

  private

  def all_dependencies(json)
    dependencies = json.fetch("dependencies")

    dependencies.each_with_object({}) do |(dependency, details), collection|
      collection[dependency] = details.fetch("version")
    end
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

  def format_dependencies(label, dependencies)
    dependencies.map do |(package, version)|
      "#{label} #{package}: #{version}"
    end
  end

  def format_updated_dependencies(dependencies)
    dependencies.map do |(package, versions)|
      "Updated #{package}: #{versions.fetch(:old)} -> #{versions.fetch(:new)}"
    end
  end
end
