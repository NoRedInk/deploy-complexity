require 'time'

module Helpers
  # tag format: production-2016-10-22-0103 or $ENV-YYYY-MM-DD-HHmm
  def parse_when(tag)
    tag.match(/-(\d{4}-\d{2}-\d{2}-\d{2}\d{2})/) do |m|
      Time.strptime(m[1], '%Y-%m-%d-%H%M')
    end
  end

  def time_between_deploys(from, to)
    deploy_time = parse_when(to)
    last_time = parse_when(from)

    hours = deploy_time && (deploy_time - last_time) / 60**2

    if hours.nil?
      "pending deploy"
    elsif hours < 24
      "after %2.1f %s" % [hours, "hours"]
    else
      "after %2.1f %s" % [(hours / 24), "days"]
    end
  end

  # converts origin/master -> master
  def safe_name(name)
    name.chomp.split(%r{/}).last
  end

  # converts a branch name like master into the closest tag or commit sha
  def reference(name)
    branch = safe_name(name)
    tag = `git tag --points-at #{name} | grep #{branch}`.chomp
    if tag.empty?
      `git rev-parse --short #{branch}`.chomp
    else
      tag
    end
  end

  GITHUB_FORMAT = "%s/blob/%s/%s"
  GIT_STATUSES = {
    "A" => :added,
    "C" => :copied,
    "D" => :deleted,
    "M" => :modified,
    "R" => :renamed,
    "T" => :changed,
    "U" => :unmerged,
    "X" => :unknown,
    "B" => :broken
  }

  def match_line(path_fragment, line)
    statuses = GIT_STATUSES.keys.join
    match_data = line.match(/^([#{statuses}])\s*(\S*(#{path_fragment}).*)$/)
    match_data[1..2]
  end

  def format_line(base, to, gh_url, path, type_letter)
    type = GIT_STATUSES[type_letter]
    case type
    when :deleted
      "☠️  "  +
        ColorizedString["Deleted: "].red +
        " Link to pre-deploy -> " +
        (GITHUB_FORMAT % [gh_url, safe_name(base), path])
    when :added
      "👶  " +
        ColorizedString["#{type.capitalize}: "].green +
        GITHUB_FORMAT % [gh_url, safe_name(to), path]
    when :modified, :copied, :changed, :renamed
      "🐒  " +
        ColorizedString["#{type.capitalize}: "].blue +
        GITHUB_FORMAT % [gh_url, safe_name(to), path]
    end
  end
end
