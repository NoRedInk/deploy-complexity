# frozen_string_literal: true

# Compare package changes for a given parser across revisions
class RevisionComparator
  def initialize(parser, files, base, to)
    @parser = parser
    @files = files
    @base = base
    @to = to
  end

  def source(revision, file)
    `git show #{revision}:#{file}`
  end

  def changes
    @files.inject([]) do |changes, file|
      old = source(@base, file)
      new = source(@to, file)
      packages = @parser.new(file: file, old: old, new: new)
      changes + packages.changes
    end
  end

  def output
    changes
    # TODO: bring back error handling
    # rescue StandardError => e
    #   puts "Error parsing: #{title}"
    #   puts e.message
    #   puts e.backtrace
  end
end
