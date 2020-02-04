#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'deploy_complexity/deploy'
require 'optparse'

def deploy(base, to, options)
  puts DeployComplexity::Deploy.new(base, to, options).generate
  puts
end

branch = "production"
last_n_deploys = nil
action = nil
options = {}

optparse = OptionParser.new do |opts| # rubocop:disable Metrics/BlockLength
  opts.banner =
    "Usage: %s [base branch] [deploy branch]" % [File.basename($PROGRAM_NAME)]
  opts.on("-b", "--branch BRANCH", String, "Specify the base branch") do |e|
    branch = DeployComplexity::Git.safe_name(e) || branch
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
  opts.on("--slack #foo,#bar", Array,
          "Report changes to slack channels") do |channels|
    if channels.any? && ENV['SLACK_WEBHOOK']
      options[:slack_channels] = channels
    else
      warn "Must specify slack channels & include SLACK_WEBHOOK in environment."
    end
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
