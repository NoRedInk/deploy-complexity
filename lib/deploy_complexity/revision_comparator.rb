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
      packages = @parser.new(file: file, old: old, new: new)
      changes + packages.changes
    end
  end

  def output(title)
    packages = changes
    return unless packages.any?

    puts title
    puts packages
    puts
  rescue StandardError => e
    puts "Error parsing: #{title}"
    puts e.message
    puts e.backtrace
    puts
  end
end
