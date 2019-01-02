# frozen_string_literal: true

# Parses git shortstat output
# `git diff --name-only v0.4.0...v0.5.0`
class ChangedFiles
  def initialize(names, versioned_url)
    @names = names.split(/\n/)
    @versioned_url = versioned_url
  end

  def migrations
    @names.grep(%r{^db/migrate}).map do |line|
      @versioned_url + line.chomp
    end
  end

  def elm_packages
    @names.grep(%r{(^|/)elm.json$}).map(&:chomp)
  end

  def ruby_dependencies
    @names.grep(/^Gemfile.lock$/).map(&:chomp)
  end
end
