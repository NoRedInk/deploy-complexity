# frozen_string_literal: true

# Compare package changes for a given parser across revisions
class RevisionComparator
  def initialize(parser, files, base, to)
    @parser = parser
    @files = files
    @base = base
    @to = to
  end

  def changes
    @files.inject([]) do |changes, file|
      old = `git show #{@base}:#{file}`
      new = `git show #{@to}:#{file}`
      packages = @parser.new(old: old, new: new)
      changes + packages.changes
    end
  end

  def output(title)
    packages = changes
    return unless packages.any?

    puts title
    puts packages
    puts
  end
end
