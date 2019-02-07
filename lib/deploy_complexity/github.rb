# frozen_string_literal: true

module DeployComplexity
  # Generate Github urls for revisions, comparisons, etc
  class Github
    def initialize(gh_url)
      @project_url = gh_url
    end

    def blob(version, path = nil)
      base = "%s/blob/%s/" % [@project_url, version]
      path ? base + path : base
    end

    def compare(base, to)
      "%s/compare/%s...%s" % [@project_url, base, to]
    end

    def pull_request(number)
      "%s/pull/%d" % [@project_url, number]
    end
  end
end
