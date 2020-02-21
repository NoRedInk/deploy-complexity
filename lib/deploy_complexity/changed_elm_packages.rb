# frozen_string_literal: true

require 'deploy_complexity/changed_dependencies'
require 'json'

module DeployComplexity
  # Takes in two elm.json files and detects which packages have changed
  class ChangedElmPackages < ChangedDependencies
    private

    def parse_dependencies(file)
      # When a elm.json file gets created or deleted we might be comparing
      # against a non-existing file. In that case we're passed an empty string.
      return {} if file.empty?

      json = JSON.parse(file)
      dependencies = json.fetch("dependencies")
      test_dependencies = json.fetch("test-dependencies")

      [
        dependencies.fetch("direct"),
        dependencies.fetch("indirect"),
        test_dependencies.fetch("direct"),
        test_dependencies.fetch("indirect")
      ].inject(&:merge)
    end
  end
end
