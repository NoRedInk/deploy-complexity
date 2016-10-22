#!/usr/bin/env ruby

# describes complexity of upcoming and past deploys, with statistics like number
# of PR's, commits, and line changes as well direct links to the github diff for
# the deploy, links to migrations, and individual PRs
#
# Examples:
#
# $ deploy-complexity.rb
# Displays code that would be promoted if staging deployed to production, or master
# was promoted to staging.
# $ deploy-complexity.rb master
# Shows the changes between last production deploy and current master
# $ deploy-complexity.rb origin/demo origin/master
# Displays the changes that would be deployed to demo
# $ deploy-complexity.rb -d 3
# Displays the last 3 deploys on production
# $ deploy-complexity.rb -b staging -d
# Show changes from every single staging deploy

require 'time'

def parse_when(tag)
  tag.match(/-(\d{4}-\d{2}-\d{2}-\d{2}\d{2})/) do |m|
    Time.strptime(m[1], '%Y-%m-%d-%H%M')
  end
end

REPO_URL = "https://github.com/NoRedInk/NoRedInk/"
PR_FORMAT = REPO_URL + "pull/%d - %s"
COMPARE_FORMAT = REPO_URL + "compare/%s...%s"
MIGRATE_FORMAT = REPO_URL + "blob/%s/db/migrate/%s"

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

def safe_name(name)
  name.chomp.split(%r{/}).last
end

def deploy(base, to, options)
  dirstat = options[:dirstat]
  stat = options[:stat]

  range = "#{base}...#{to}"

  revision = `git rev-parse --short #{to}`.chomp

  time_delta = time_between_deploys(safe_name(base), safe_name(to))

  commits = `git log --oneline #{range}`.split(/\n/)
  merges = commits.grep(/Merge/)

  shortstat = `git diff --shortstat --summary #{range}`.split(/\n/)
  migrations = shortstat.grep(/migrate/).map do |line|
    line.match(%r{db/migrate/(.*)$}) do |m|
      MIGRATE_FORMAT % [safe_name(to), m[1]]
    end
  end

  dirstat = `git diff --dirstat=lines,cumulative #{range}` if dirstat
  stat = `git diff --stat #{range}` if stat

  prs = merges.map do |line|
    line.match(/pull request #(\d+) from (.*)$/) do |m|
      [m[1].to_i, safe_name(m[2])]
    end
  end.compact

  puts "Deploy tag %s [%s]" % [to, revision]
  if !commits.empty?
    puts "%d prs of %d merges, %d commits %s" %
         [prs.count, merges.count, commits.count, time_delta]
    puts shortstat.first.strip unless shortstat.empty?
    puts COMPARE_FORMAT % [safe_name(base), safe_name(to)]
    puts "Migrations:", migrations if migrations.any?
    puts "Pull Requests:", prs.map { |x| PR_FORMAT % x } if prs.any?
    puts "Commits:", commits if prs.size.zero?
    puts "Dirstats:", dirstat if dirstat
    puts "Stats:", stat if stat
  else
    puts "redeployed %s %s" % [base, time_delta]
  end
  puts
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
  opts.on_tail("-h", "--help", "Show this message") { abort(opts.to_s) }
end

optparse.parse!(ARGV)
action ||= if ARGV.size == 0
  "promote"
elsif ARGV.size <= 2
  "diff"
end

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
