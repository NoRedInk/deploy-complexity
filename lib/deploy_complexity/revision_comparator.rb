# frozen_string_literal: true

module DeployComplexity
  # Compare package changes for a given parser across revisions
  class RevisionComparator
    def initialize(parser, files, base, to)
      @parser = parser
      @files = files
      @base = base
      @to = to
    end

    # return [Array<String>] Should return an array of strings, even if there is a parsing error
    def output
      changes
    rescue StandardError => e
      [
        e.message,
        e.backtrace.join("/n")
      ]
    end

    private

    def source(revision, file)
      # A file may legitimately not exist, if it was created or deleted between
      # the old and new revisions. `git show` will log to stderr in that case,
      # introducing unhelpful noise in the complexity report. To prevent this we
      # redirect stderr to `/dev/null`.
      `git show #{revision}:#{file} 2>/dev/null`
    end

    def changes
      @files.inject([]) do |changes, file|
        old = source(@base, file)
        new = source(@to, file)
        packages = @parser.new(file: file, old: old, new: new)
        changes + packages.changes
      end
    end
  end
end
