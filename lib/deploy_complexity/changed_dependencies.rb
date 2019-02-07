# frozen_string_literal: true

require 'deploy_complexity/dependency'

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
      dependencies.reject(&:unchanged?)
    end

    private

    # This should be implemented in the child classes
    # @param [String] the dependency file to be parsed
    # @return [ Object{String => String} ] map of the dependency name to the version
    def parse_dependencies(_file)
      {}
    end

    def dependencies
      packages = (@new_dependencies.keys + @old_dependencies.keys).uniq.sort
      packages.map do |package|
        DeployComplexity::Dependency.with(
          package: package,
          current: @new_dependencies.fetch(package, nil),
          previous: @old_dependencies.fetch(package, nil),
          file: @file
        )
      end
    end
  end
end
