#!/usr/bin/env ruby

require 'time'
require 'bundler/setup'
require 'deploy_complexity/version'
require 'colorized_string'

# tag format: production-2016-10-22-0103 or $ENV-YYYY-MM-DD-HHmm
def parse_when(tag)
  tag.match(/-(\d{4}-\d{2}-\d{2}-\d{2}\d{2})/) do |m|
    Time.strptime(m[1], '%Y-%m-%d-%H%M')
  end
end

PR_FORMAT = "> %s/pull/%d %1s %s"
COMPARE_FORMAT = "> %s/compare/%s...%s"
MIGRATE_FORMAT = "%s/blob/%s/db/migrate/%s"
RESQUE_FORMAT = "%s/blob/%s/app/jobs/%s"

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

def print_section(title, items)
  if items.any?
    puts
    puts title, items
  end
end

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
# Deduces the status of a file change from its line of the diff
# e.g. "M       exe/deploy-complexity.rb" -> MODIFIED
def get_modification_type(line)
  statuses = GIT_STATUSES.keys.join
  letter = line.match(/^([#{statuses}])/)[1]
  GIT_STATUSES.fetch(letter, :unknown)
end

def random_color
  ColorizedString.colors.sample
end

def changes_from_namestat(base, to, gh_url, namestat, path_fragment, formatter)
  namestat.grep(/#{path_fragment}/).map do |line|
    type = get_modification_type(line)
    line.match(/#{path_fragment}(.*)$/) do |m|
      case type
      when :deleted
        "☠️  "  +
        ColorizedString["Deleted: "].red +
        " Link to pre-deploy -> " +
        (formatter % [gh_url, safe_name(base), m[1]])
      when :added
        "👶  " +
        ColorizedString["#{type.capitalize}: "].green +
        formatter % [gh_url, safe_name(to), m[1]]
      when :modified, :copied, :changed, :renamed
        "🐒  " +
        ColorizedString["#{type.capitalize}: "].blue +
        formatter % [gh_url, safe_name(to), m[1]]
      else
        raise "Unexpected line in diff: #{line}"
      end
    end
  end
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

# deploys are the delta from base -> to, so to contains commits to add to base
def deploy(base, to, options)
  gh_url = options[:gh_url]
  dirstat = options[:dirstat]
  show_stat = options[:stat]

  range = "#{base}...#{to}"

  # tag_revision = `git rev-parse --short #{to}`.chomp
  revision = `git rev-list --abbrev-commit -n1 #{to}`.chomp

  time_delta = time_between_deploys(safe_name(base), safe_name(to))

  commits = `git log --oneline #{range}`.split(/\n/)
  merges = commits.grep(/Merges|\#\d+/)

  dirstat = `git diff --dirstat=lines,cumulative #{range}` if dirstat
  namestat_lines = `git diff --name-status #{range}`.split(/\n/)
  shortstat_lines = `git diff --shortstat --summary #{range}`.split(/\n/)
  stat = `git diff --stat #{range}` if show_stat

  migrations = changes_from_namestat(base, to, gh_url, namestat_lines, "db/migrate/", MIGRATE_FORMAT)

  resque_changes = changes_from_namestat(base, to, gh_url, namestat_lines, "app/jobs/", RESQUE_FORMAT)

  # TODO: investigate summarizing language / spec content based on file suffix,
  # and possibly per PR, or classify frontend, backend, spec changes

  pull_requests = merges.map do |line|
    line.match(/pull request #(\d+) from (.*)$/) do |m|
      PR_FORMAT % [gh_url, m[1].to_i, "-", safe_name(m[2])]
    end || line.match(/(\w+)\s+(.*)\(\#(\d+)\)/) do |m|
      PR_FORMAT % [gh_url, m[3].to_i, "S", m[2]] # squash merge
    end
  end.compact

  title = "Deploy tag %s [%s]" % [to, revision]
  puts title
  puts ColorizedString[" " * title.length].colorize(background: random_color), "\n"

  if !commits.empty?
    puts "Summary:"
    puts "> %d pull requests of %d merges, %d commits %s" %
         [pull_requests.count, merges.count, commits.count, time_delta]
    puts "> " + shortstat_lines.first.strip unless shortstat_lines.empty?
    puts
    puts "Compare:"
    puts COMPARE_FORMAT % [gh_url, reference(base), reference(to)]
    print_section "Migrations:", migrations
    print_section "Resque Changes:", resque_changes
    if pull_requests.any?
      # FIXME: there may be commits in the deploy unassociated with a PR
      puts
      puts "Pull Requests:"
      puts pull_requests
    else
      puts "Commits:", commits
    end
    puts "Dirstats:", dirstat if dirstat
    puts "Stats:", stat if show_stat
  else
    puts "redeployed %s %s" % [base, time_delta]
  end
  puts "\n" * 3
end

branch = "production"
last_n_deploys = nil
action = nil
options = {}

require 'optparse'
optparse = OptionParser.new do |opts|
  opts.banner =
    "Usage: %s [[base branch] deploy branch]" % [File.basename($PROGRAM_NAME)]
  opts.on("-b", "--branch BRANCH", String, "Specify the base branch") do |e|
    branch = safe_name(e) || branch
  end
  opts.on("-d", "--deploys [N]", Integer,
          "Show historical deploys, shows all if N is not specified") do |e|
    action = "history"
    last_n_deploys = e.to_i
    last_n_deploys = nil if last_n_deploys.zero?
  end
  opts.on("--dirstat",
          "Statistics on directory changes") { options[:dirstat] = true }
  opts.on("--stat",
          "Statistics on file changes") { options[:stat] = true }
  opts.on("--git-dir DIR", String,
          "Project directory to run git commands from") do |dir|
    Dir.chdir(dir)
  end
  opts.on("--gh-url URL", String,
          "Github project url to construct links from") do |url|
    options[:gh_url] = url
  end
  opts.on_tail("-v", "--version", "Show version info and exit") do
    abort <<EOF
deploy-complexity.rb #{DeployComplexity::VERSION}
Copyright (C) 2016 NoRedInk (MIT License)
EOF
  end
  opts.on_tail("-h", "--help", "Show this help message and exit") do
    abort(opts.to_s)
  end
end

optparse.parse!(ARGV)
action ||= if ARGV.size == 0
  "promote"
elsif ARGV.size <= 2
  "diff"
end

options[:gh_url] ||=
  "https://github.com/" + `git config --get remote.origin.url`[/:(.+).git/, 1]

deploys = `git tag -l | grep #{branch}`.split(/\n/).drop(1)
case action
when "history"
  deploys = deploys.last(1+last_n_deploys) if last_n_deploys
  deploys.each_cons(2) do |(base, to)|
    deploy(base, to, options)
  end
when "promote"
  deploy("origin/production", "origin/staging", options)
  deploy("origin/staging", "origin/master", options)
when "diff"
  to = ARGV.pop
  base = ARGV.pop || deploys.last.chomp
  deploy(base, to, options)
else
  abort(optparse.to_s)
end
