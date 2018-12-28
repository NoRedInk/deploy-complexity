# frozen_string_literal: true

require 'deploy_complexity/changed_dependencies'

# Detects changes in two package-lock.json files
class ChangedJavascriptPackages < ChangedDependencies
  private

  def all_dependencies(json)
    dependencies = json.fetch("dependencies")

    dependencies.each_with_object({}) do |(dependency, details), collection|
      collection[dependency] = details.fetch("version")
    end
  end
end
