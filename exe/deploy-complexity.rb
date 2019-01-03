#!/usr/bin/env ruby
# frozen_string_literal: true

require 'time'
require 'bundler/setup'
require 'deploy_complexity/slack_formatter'
require 'deploy_complexity/version'
require 'deploy_complexity/revision_comparator'
require 'deploy_complexity/changed_files'
require 'deploy_complexity/changed_elm_packages'
require 'deploy_complexity/changed_javascript_packages'
require 'deploy_complexity/changed_ruby_gems'

# tag format: production-2016-10-22-0103 or $ENV-YYYY-MM-DD-HHmm
def parse_when(tag)
  tag.match(/-(\d{4}-\d{2}-\d{2}-\d{2}\d{2})/) do |m|
    Time.strptime(m[1], '%Y-%m-%d-%H%M')
  end
end

COMPARE_FORMAT = "%s/compare/%s...%s"

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

def pull_requests(merges, gh_url)
  prs = merges.map do |line|
    line.match(/pull request #(\d+) from (.*)$/) do |m|
      [gh_url, m[1].to_i, "-", safe_name(m[2])]
    end || line.match(/(\w+)\s+(.*)\(\#(\d+)\)/) do |m|
      [gh_url, m[3].to_i, "S", m[2]] # squash merge
    end
  end
  prs.compact.map { |x| "%s/pull/%d %1s %s" % x }
end

def list_migrations(changed_files)
  migrations = changed_files.migrations
  return unless migrations.any?

  puts "Migrations:"
  puts migrations
  puts
end

def file_changes(changed_files, base:, to:)
  list_migrations(changed_files)

  RevisionComparator.new(
    ChangedElmPackages, changed_files.elm_packages, base, to
  ).output("Changed Elm packages:")

  RevisionComparator.new(
    ChangedRubyGems, changed_files.ruby_dependencies, base, to
  ).output("Ruby dependency changes:")

  RevisionComparator.new(
    ChangedJavascriptPackages, changed_files.javascript_dependencies, base, to
  ).output("Javascript Dependency Changes:")

  # TODO: scan for changes to app/jobs and report changes to params
end

# deploys are the delta from base -> to, so to contains commits to add to base
def deploy(base, to, options)
  gh_url = options[:gh_url]
  dirstat = options[:dirstat]
  stat = options[:stat]

  range = "#{base}...#{to}"

  # tag_revision = `git rev-parse --short #{to}`.chomp
  revision = `git rev-list --abbrev-commit -n1 #{to}`.chomp

  time_delta = time_between_deploys(safe_name(base), safe_name(to))

  commits = `git log --oneline #{range}`.split(/\n/)
  merges = commits.grep(/Merges|\#\d+/)

  shortstat = `git diff --shortstat --summary #{range}`.split(/\n/)
  names_only = `git diff --name-only #{range}`
  versioned_url = "#{gh_url}/blob/#{safe_name(to)}/"

  dirstat = `git diff --dirstat=lines,cumulative #{range}` if dirstat
  # TODO: investigate summarizing language / spec content based on file suffix,
  # and possibly per PR, or classify frontend, backend, spec changes
  stat = `git diff --stat #{range}` if stat

  pull_requests = pull_requests(merges, gh_url)

  # if !commits.empty?
  #   puts "%d pull requests of %d merges, %d commits %s" %
  #        [pull_requests.count, merges.count, commits.count, time_delta]
  #   puts shortstat.first.strip unless shortstat.empty?
  #   puts COMPARE_FORMAT % [gh_url, reference(base), reference(to)]
  #   list_migrations(changed_files)
  #   list_changed_elm_dependencies(changed_files, base: base, to: to)
  #   list_changed_javascript_dependencies(changed_files, base: base, to: to)
  #   list_changed_ruby_dependencies(changed_files, base: base, to: to)
  #   if pull_requests.any?
  #     # FIXME: there may be commits in the deploy unassociated with a PR
  #     puts "Pull Requests:", pull_requests
  #   else
  #     puts "Commits:", commits
  #   end
  #   puts "Dirstats:", dirstat if dirstat
  #   puts "Stats:", stat if stat
  # else
  #   puts "redeployed %s %s" % [base, time_delta]
  # end
  # puts

  formatter = SlackFormatter.with(
    to: to,
    base: base,
    revision: revision,
    commits: commits,
    pull_requests: pull_requests,
    merges: merges,
    shortstat: shortstat,
    time_delta: time_delta,
    gh_url: gh_url
  )

  puts formatter.format
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
    abort <<~BOILERPLATE
      deploy-complexity.rb #{DeployComplexity::VERSION}
      Copyright (C) 2016 NoRedInk (MIT License)
    BOILERPLATE
  end
  opts.on_tail("-h", "--help", "Show this help message and exit") do
    abort(opts.to_s)
  end
end

optparse.parse!(ARGV)
action ||=
  if ARGV.size.zero?
    "promote"
  elsif ARGV.size <= 2
    "diff"
  end

options[:gh_url] ||=
  "https://github.com/" + `git config --get remote.origin.url`[/:(.+).git/, 1]

deploys = `git tag -l | grep #{branch}`.split(/\n/).drop(1)
case action
when "history"
  deploys = deploys.last(1 + last_n_deploys) if last_n_deploys
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

# rubocop:enable Style/FormatStringToken
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/PerceivedComplexity
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/BlockLength
