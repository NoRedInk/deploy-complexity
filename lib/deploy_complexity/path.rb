# frozen_string_literal: true

module DeployComplexity
  # Helper methods for File/Pathname operations
  module Path
    # Searches for a directory containing file as child in any of the directories
    # in the hierarchy above it. Returns nil on no match.
    # @param [Pathname] path
    # @param [Pathname] file
    # @return [Pathname, nil]
    def self.locate_file_in_ancestors(path, file)
      if path.children.find { |x| x.basename == file }
        path
      elsif path == Pathname.new('/')
        nil
      else
        locate_file_in_ancestors(path.parent, file)
      end
    end
  end
end
