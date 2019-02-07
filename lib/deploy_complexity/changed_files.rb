# frozen_string_literal: true

module DeployComplexity
  # Parses git shortstat output
  # `git diff --name-only v0.4.0...v0.5.0`
  class ChangedFiles
    def initialize(names)
      @names = names.split(/\n/)
    end

    def migrations
      @names.grep(%r{^db/migrate}).map(&:chomp)
    end

    def elm_packages
      @names.grep(%r{(^|/)elm\.json$}).map(&:chomp)
    end

    def ruby_dependencies
      @names.grep(%r{(^|/)Gemfile\.lock$}).map(&:chomp)
    end

    def javascript_dependencies
      @names.grep(%r{(^|/)package-lock\.json$}).map(&:chomp)
    end
  end
end
