#!/usr/bin/env ruby
# frozen_string_literal: true

require 'deploy_complexity/checklists'
require 'deploy_complexity/git'
require 'deploy_complexity/pull_request'
require 'optparse'
require 'octokit'

# options and validation
class Options
  attr_writer :branch, :token, :org, :repo, :dry_run, :checklist

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

OptionParser.new do |opts|
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

require 'git'
require 'logger'

puts "Found pull request #{pr}"
# TODO pass in git base-dir as an argument instead of defaulting to parent
git = Git.open("..", log: Logger.new(STDOUT))
# TODO handle multiple ancestors?
common_ancestor = git.merge_base(pr.base, pr.head).first.sha

diff = git.gtree(common_ancestor).diff(pr.head)
files_changed = diff.map { |file| file.path }

# conditionally load externally defined checklist from project
if options.checklist
  puts "Loading external configuration from %s" % [options.checklist]
  load options.checklist
end

checklists = Checklists.for_files(Checklists.checklists, files_changed)
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
