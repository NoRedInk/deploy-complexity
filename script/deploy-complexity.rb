#!/usr/bin/env ruby

require 'time'

def parse_when(tag)
  tag.match(/-(\d{4}-\d{2}-\d{2}-\d{2}\d{2})/) do |m|
    Time.strptime(m[1], '%Y-%m-%d-%H%M')
  end
end

REPO_URL = "https://github.com/NoRedInk/NoRedInk/"
PR_FORMAT = REPO_URL + "pull/%d - %s"
COMPARE_FORMAT= REPO_URL + "compare/%s...%s"
MIGRATE_FORMAT = REPO_URL + "blob/%s/db/migrate/%s"

def time_between_deploys(from, to)
  deploy_time = parse_when(to)
  last_time = parse_when(from)

  hours = if deploy_time
    (deploy_time - last_time) / 60**2
  end

  if hours.nil?
    "pending deploy"
  elsif hours < 24
    "after %2.1f %s" % [hours, "hours"]
  else
    "after %2.1f %s" % [(hours/24), "days"]
  end
end

def safe_name(name)
  name.chomp.split(%r{/}).last
end

def deploy(from, to)
  range = "#{from}...#{to}"

  revision = `git rev-parse --short #{to}`.chomp

  time_delta = time_between_deploys(safe_name(from), safe_name(to))

  commits = `git log --oneline #{range}`.split(/\n/)
  merges = commits.grep(/Merge/)

  shortstat = `git diff --shortstat --summary #{range}`.split(/\n/)
  migrations = shortstat.grep(/migrate/).map do |line|
    line.match(%r{db/migrate/(.*)$}) do |m|
      MIGRATE_FORMAT % [safe_name(to), m[1]]
    end
  end

  prs = merges.map { |line|
    line.match(/pull request #(\d+) from (.*)$/) do |m|
      [m[1].to_i, safe_name(m[2])]
    end
  }.compact

  puts "Deploy tag %s [%s]" % [to, revision]
  if commits.size > 0
    puts "%d prs of %d merges, %d commits %s" %
         [prs.count, merges.count, commits.count, time_delta]
    puts shortstat.first.strip unless shortstat.empty?
    puts COMPARE_FORMAT % [safe_name(from),safe_name(to)]
    puts "Migrations:", migrations if migrations.any?
    puts "Pull Requests:", prs.map { |x| PR_FORMAT % x } if prs.any?
    puts "Commits:", commits if prs.size.zero?
  else
    puts "redeployed %s %s" % [from, time_delta]
  end
  puts
end

branch = nil
last_n_deploys = nil
action = "staging"

require 'optparse'
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: %s [base branch]..[deploy branch]" % [File.basename($PROGRAM_NAME)]
  opts.on("-b", "--branch-history [BRANCH]", String, "Show historical deploys from branch") do |e|
    branch = e || "production"
  end
  opts.on("-d", "--deploys [N]", Integer, "Only show last N deploys",
          "Only works with --branch-history") do |e|
    last_n_deploys = e.to_i
    last_n_deploys = 5 if last_n_deploys.zero?
  end
  opts.on_tail("-h", "--help", "Show this message") { abort(opts.to_s) }
end

optparse.parse!(ARGV)
if ARGV.size == 0
  action = "promote"
elsif ARGV.size <= 2
  action = "diff"
else
  abort(optparse.to_s)
end

if branch
  deploys = `git tag -l | grep #{branch}`.split(/\n/).drop(1)
  deploys = deploys.last(1+last_n_deploys) if last_n_deploys
  deploys.each_cons(2) do |(from, to)|
    deploy(from, to)
  end
elsif action == "promote"
  deploy("origin/production", "origin/staging")
  deploy("origin/staging", "origin/master")
else
  to = ARGV.pop
  from = ARGV.pop || `git tag -l | grep production`.split(/\n/).last.chomp
  deploy(from, to)
end
