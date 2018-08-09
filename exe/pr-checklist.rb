#!/usr/bin/env ruby
# frozen_string_literal: true

require 'deploy_complexity/checklists'
require 'deploy_complexity/pull_request'
require 'optparse'

# options and validation
class Options
  attr_writer :branch, :token, :org, :repo

  def branch
    # origin/master or master are both fine, but we need to drop origin/
    b = (@branch || ENV['GIT_BRANCH'])&.chomp&.split(%r{/})&.last
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
end.parse!

puts "Checking branch #{options.branch}..."
pr = PullRequest.new(options.branch, options.token, options.org, options.repo)

unless pr.present?
  puts "Could not find pull request!"
  exit 0
end

puts "Found pull request #{pr}"
files_changed = Checklists.get_files_changed(pr.base, pr.head)
new_checklists =
  pr.append_checklists(Checklists.checklists_for_files(files_changed))

new_checklists.each do |checklist|
  puts "Added the #{checklist} checklist to this PR."
end

if new_checklists.empty?
  puts "Didn't need to add any checklists on this PR."
else
  pr.add_checklist_comment(new_checklists)
  puts "Left a comment about the new checklists."
end
