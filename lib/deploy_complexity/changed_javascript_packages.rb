# frozen_string_literal: true

require 'deploy_complexity/changed_dependencies'
require 'json'

module DeployComplexity
  # Detects changes in two package-lock.json files
  class ChangedJavascriptPackages < ChangedDependencies
    private

    def parse_dependencies(file)
      json = JSON.parse(file)
      dependencies = json.fetch("dependencies")

      dependencies.transform_values do |details|
        details.fetch("version")
      end
    end
  end
end
