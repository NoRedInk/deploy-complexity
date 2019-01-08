#!/usr/bin/env ruby
# frozen_string_literal: true

require 'time'
require 'bundler/setup'
require 'deploy_complexity/slack_output_formatter'
require 'deploy_complexity/cli_output_formatter'
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

# TODO: consider moving this to a separate parser and testing
def pull_requests(merges, gh_url)
  merges.map do |line|
    line.match(/pull request #(\d+) from (.*)$/) do |m|
      {
        gh_url: gh_url,
        pr_number: m[1].to_i,
        joiner: "-",
        name: safe_name(m[2])
      }
    end || line.match(/(\w+)\s+(.*)\(\#(\d+)\)/) do |m|
      {
        gh_url: gh_url,
        pr_number: m[3].to_i,
        joiner: "S",
        name: m[2]
      }
    end
  end.compact
end

# deploys are the delta from base -> to, so to contains commits to add to base
def deploy(base, to, options)
  gh_url = options[:gh_url]
  dirstat = options[:dirstat]
  stat = options[:stat]
  slack_format = options[:slack_format]

  range = "#{base}...#{to}"

  # tag_revision = `git rev-parse --short #{to}`.chomp
  revision = `git rev-list --abbrev-commit -n1 #{to}`.chomp

  time_delta = time_between_deploys(safe_name(base), safe_name(to))

  commits = `git log --oneline #{range}`.split(/\n/)
  merges = commits.grep(/Merges|\#\d+/)

  shortstat = `git diff --shortstat --summary #{range}`.split(/\n/)
  names_only = `git diff --name-only #{range}`
  versioned_url = "#{gh_url}/blob/#{safe_name(to)}/"
  changed_files = DeployComplexity::ChangedFiles.new(names_only, versioned_url)

  dirstat = `git diff --dirstat=lines,cumulative #{range}` if dirstat
  # TODO: investigate summarizing language / spec content based on file suffix,
  # and possibly per PR, or classify frontend, backend, spec changes
  stat = `git diff --stat #{range}` if stat

  # TODO: scan for changes to app/jobs and report changes to params
  formatter_attributes = {
    to: to,
    base: base,
    revision: revision,
    commits: commits,
    pull_requests: pull_requests(merges, gh_url),
    merges: merges,
    shortstat: shortstat,
    dirstat: dirstat,
    stat: stat,
    time_delta: time_delta,
    gh_url: gh_url,
    base_reference: reference(base),
    to_reference: reference(to),
    migrations: changed_files.migrations,
    elm_packages: DeployComplexity::RevisionComparator.new(
      DeployComplexity::ChangedElmPackages, changed_files.elm_packages, base, to
    ).output,
    ruby_dependencies: DeployComplexity::RevisionComparator.new(
      DeployComplexity::ChangedRubyGems, changed_files.ruby_dependencies, base, to
    ).output,
    javascript_dependencies: DeployComplexity::RevisionComparator.new(
      DeployComplexity::ChangedJavascriptPackages, changed_files.javascript_dependencies, base, to
    ).output
  }

  formatter = if slack_format
                DeployComplexity::SlackOutputFormatter.with(formatter_attributes)
              else
                DeployComplexity::CliOutputFormatter.with(formatter_attributes)
              end

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
  opts.on("--slack-format",
          "Format output for Slack") { options[:slack_format] = true }
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
