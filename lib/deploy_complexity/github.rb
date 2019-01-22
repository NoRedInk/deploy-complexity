# frozen_string_literal: true

module DeployComplexity
  # Generate Github urls for revisions, comparisons, etc
  class Github
    def initialize(gh_url)
      @project_url = gh_url
    end

    def compare(base, to)
      "%s/compare/%s...%s" % [@project_url, base, to]
    end
  end
end
