# frozen_string_literal: true

require 'deploy_complexity/changed_dependencies'
require 'pry'

# Takes in two package-lock.json files and detects which packages have changed
class ChangedRubyGems < ChangedDependencies
  private

  # See: https://stackoverflow.com/questions/38800129/parsing-a-gemfile-lock-with-bundler
  def parse_dependencies(file)
    lockfile_parser = Bundler::LockfileParser.new(file)

    lockfile_parser.specs.each_with_object({}) do |spec, collection|
      collection[spec.name] = spec.version
    end
  end
end
