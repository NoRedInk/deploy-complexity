#!/usr/bin/env ruby
# frozen_string_literal: true

require 'deploy_complexity/checklists'
require 'deploy_complexity/git'
require 'deploy_complexity/pull_request'
require 'deploy_complexity/path'
require 'optparse'
require 'octokit'
require 'git'

# options and validation
class Options
  attr_writer :git_dir, :branch, :token, :org, :repo, :dry_run, :checklist

  # Use the supplied git dir, find the .git directory in a parent directory
  # recursively or fail out by using the current directory.
  def git_dir
    (
      @git_dir ||
      DeployComplexity::Path.locate_file_in_ancestors(
        Pathname.getwd, Pathname.new('.git')
      ) ||
      "."
    ).to_s
  end

  def branch
    # origin/master or master are both fine, but we need to drop origin/
    b = DeployComplexity::Git.safe_name(@branch || ENV['GIT_BRANCH'])
    raise "--branch must be set" unless b

    b
  end

  def token
    t = @token || ENV['GITHUB_TOKEN']
    raise "--token or GITHUB_TOKEN must be set" unless t

    t
  end

  def org
    @org || "NoRedInk"
  end

  def repo
    @repo || "NoRedInk"
  end

  def dry_run
    @dry_run || false
  end

  def checklist
    @checklist || nil
  end
end

options = Options.new

OptionParser.new do |opts| # rubocop:disable Metrics/BlockLength
  opts.on(
    "--git-dir DIR", String,
    "Project directory to run git commands from"
  ) { |dir| options.git_dir = dir }

  opts.on(
    "-b", "--branch BRANCH", String,
    "Which branch should we examine?"
  ) { |branch| options.branch = branch }

  opts.on(
    "-t", "--token token", String,
    "Github access token (default: ENV['GITHUB_TOKEN'])"
  ) { |token| options.token = token }

  opts.on(
    "-o", "--org org", String,
    "Github organization to query for PRs (default: NoRedInk)"
  ) { |org| options.org = org }

  opts.on(
    "-r", "--repo repo", String,
    "Github repository to query for PRs (default: NoRedInk)"
  ) { |repo| options.repo = repo }

  opts.on(
    "-n", "--dry-run",
    "Check things, but do not make any edits or comments"
  ) { |dry_run| options.dry_run = dry_run }

  opts.on(
    "-c", "--custom-checklist config.rb", String,
    "Specify external ruby file to load checklists from"
  ) { |checklist| options.checklist = checklist }
end.parse!

puts "Checking branch #{options.branch}..."
client = Octokit::Client.new(access_token: options.token)
pr = PullRequest.new(client, options.org, options.repo, options.branch)

puts "!!! IN DRY RUN MODE, NOT DOING ANY OF THESE THINGS !!!" if options.dry_run

unless pr.present?
  puts "Could not find pull request!"
  exit 0
end

puts "Found pull request #{pr}"

git = Git.open(options.git_dir)

# Calculate the common ancestor where pr.head diverged from pr.base, so the diff
# is of the unique changes in pr.head and not the changes that have since merged
# into pr.base. Unfortunately, it's not clear how to determine which merge base
# is best if there are multiple, so just selecting the first merge base.
common_ancestor = git.merge_base(pr.base, pr.head).first.sha

# Returns a Git::Diff object, see
# https://github.com/ruby-git/ruby-git/blob/master/lib/git/diff.rb for
# documentation, but roughly it's an Enumerable set of Git::FileDiff objects,
# each of which respond to #patch for the diff contents, or #path for each file
# changed.
pull_request_changes = git.gtree(common_ancestor).diff(pr.head)

# conditionally load externally defined checklist from project
if options.checklist
  puts "Loading external configuration from %s" % [options.checklist]
  load options.checklist
end

checklists = Checklists.for_files(Checklists.checklists, pull_request_changes)
new_checklists = pr.update_with_checklists(checklists, options.dry_run)

new_checklists.each do |checklist, files|
  puts "Added the #{checklist} checklist to this PR since these files changed: #{files.join(', ')}"
end

checklists.each do |checklist, files|
  next if new_checklists[checklist]

  puts "Already added the #{checklist} checklist to this PR since these files changed: #{files.join(', ')}"
end

if new_checklists.empty?
  puts "Didn't need to add any checklists on this PR."
else
  puts "Left a comment about the new checklists."
end
