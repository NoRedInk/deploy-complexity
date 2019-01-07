# frozen_string_literal: true

require 'deploy_complexity/changed_dependencies'

module DeployComplexity
  # Takes in two package-lock.json files and detects which packages have changed
  class ChangedRubyGems < ChangedDependencies
    private

    # See: https://stackoverflow.com/questions/38800129/parsing-a-gemfile-lock-with-bundler
    def parse_dependencies(file)
      lockfile_parser = Bundler::LockfileParser.new(file)

      lockfile_parser.specs.each_with_object({}) do |spec, collection|
        version = spec.version.to_s

        # Consider Git sources separately so we know where they are coming from
        version += " (GIT #{spec.source.uri} #{spec.source.revision})" if spec.source.is_a?(Bundler::Source::Git)

        collection[spec.name] = version
      end
    end
  end
end
