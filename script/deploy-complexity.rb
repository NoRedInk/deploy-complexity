#!/bin/usr/env ruby

require 'time'

def parse_when(tag)
  if m = tag.match(/-(\d{4}-\d{2}-\d{2}-\d{2}\d{2})/)
    Time.strptime(m[1], '%Y-%m-%d-%H%M')
  end
end

REPO_URL = "https://github.com/NoRedInk/NoRedInk/"
PR_FORMAT = REPO_URL + "pull/%d"
COMPARE_FORMAT= REPO_URL + "compare/%s...%s"

def time_between_deploys(from, to)
  deploy_time = parse_when(to)
  last_time = parse_when(from)

  hours = if deploy_time
    (deploy_time - last_time) / 60**2
  end

  time_delta = if hours.nil?
    "pending deploy"
  elsif hours < 24
    "after %2.1f %s" % [hours, "hours"]
  else
    "after %2.1f %s" % [(hours/24), "days"]
  end
end

def deploy(from, to)
  delta = `git describe --match="production*" #{to}~1`.chomp
  revision = `git rev-parse --short #{to}`.chomp

  commits = if m = delta.match(/-(\d+)-g/)
    m[1].to_i
  else
    0
  end

  time_delta = time_between_deploys(from, to)

  merges = `git log --oneline --merges -m --first-parent #{from}..#{to}`.split(/\n/)

  prs = merges.map do |line|
    if m = line.match(/pull request #(\d+) from (.*)$/)
      m[1].to_i
    end
  end.compact

  puts "Deploy %s [%s]" % [to, revision]
  if commits > 1
    puts "%d prs of %d merges, %d commits %s" %
         [prs.count, merges.count, commits, time_delta]
    puts COMPARE_FORMAT % [from,to]
    puts prs.map { |x| PR_FORMAT % x }
  else
    puts "redeployed %s %s" % [from, time_delta]
  end
  puts
end

deploys = `git tag -l | grep production`.split(/\n/).drop(1)
deploys.each_cons(2) do |(from, to)|
  deploy(from, to)
end

#deploy("origin/production", "origin/staging")
