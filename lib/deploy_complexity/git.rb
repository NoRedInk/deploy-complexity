# frozen_string_literal: true

module DeployComplexity
  # Helper functions for managing git remotes and branch names
  module Git
    module_function

    # converts origin/master -> master
    def safe_name(name)
      name&.chomp&.delete_prefix('origin/')
    end
  end
end
