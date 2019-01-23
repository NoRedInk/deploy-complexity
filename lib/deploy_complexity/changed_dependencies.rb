# frozen_string_literal: true

module DeployComplexity
  # Detects and formats changes in dependencies
  # This is the parent class - each type of dependency file should implement
  # it's own version of this. See changed_javascript_packages.rb for an example.
  class ChangedDependencies
    def initialize(file:, old:, new:)
      @file = file
      @old_dependencies = parse_dependencies(old)
      @new_dependencies = parse_dependencies(new)
    end

    def changes
      [
        format_dependencies("Added", added_dependencies),
        format_dependencies("Removed", removed_dependencies),
        format_updated_dependencies(updated_dependencies)
      ].flatten
    end

    private

    # This should be implemented in the child classes
    # @param [String] the dependency file to be parsed
    # @return [ Object{String => String} ] map of the dependency name to the version
    def parse_dependencies(_file)
      {}
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
        "#{label} #{package}: #{version} (#{@file})"
      end
    end

    def format_updated_dependencies(dependencies)
      dependencies.map do |(package, versions)|
        "Updated #{package}: #{versions.fetch(:old)} -> #{versions.fetch(:new)} (#{@file})"
      end
    end
  end
end
