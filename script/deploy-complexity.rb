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

  if hours.nil?
    "pending deploy"
  elsif hours < 24
    "after %2.1f %s" % [hours, "hours"]
  else
    "after %2.1f %s" % [(hours/24), "days"]
  end
end

def base_tag(from)
  base = case from
  when /staging/
    "staging"
  when /demo/
    "demo"
  else
    "production"
  end

  `git describe --match="#{base}*" #{to}~1`.chomp
end

def safe_name(name)
  name.chomp.split(%r{/}).last
end

def deploy(from, to)
  from = safe_name(from)
  to = safe_name(to)

  revision = `git rev-parse --short #{to}`.chomp

  time_delta = time_between_deploys(from, to)

  commits = `git log --oneline #{from}...#{to}`.split(/\n/)
  merges = commits.grep(/Merge/)

  prs = merges.map do |line|
    if m = line.match(/pull request #(\d+) from (.*)$/)
      m[1].to_i
    end
  end.compact

  puts "Deploy %s [%s]" % [to, revision]
  if commits.count > 0
    puts "%d prs of %d merges, %d commits %s" %
         [prs.count, merges.count, commits.count, time_delta]
    puts COMPARE_FORMAT % [from,to]
    puts prs.map { |x| PR_FORMAT % x }
  else
    puts "redeployed %s %s" % [from, time_delta]
  end
  puts
end

last_n_deploys = nil
deploys = `git tag -l | grep production`.split(/\n/).drop(1)
deploys = deploys.last(1+last_n_deploys) if last_n_deploys
deploys.each_cons(2) do |(from, to)|
  deploy(from, to)
end

# deploy("production", "staging")
