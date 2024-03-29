# frozen_string_literal: true

require 'time'
require 'deploy_complexity/slack_output_formatter'
require 'deploy_complexity/cli_output_formatter'
require 'deploy_complexity/version'
require 'deploy_complexity/revision_comparator'
require 'deploy_complexity/changed_files'
require 'deploy_complexity/changed_elm_packages'
require 'deploy_complexity/changed_javascript_packages'
require 'deploy_complexity/changed_ruby_gems'
require 'deploy_complexity/git'
require 'deploy_complexity/github'

module DeployComplexity
  # The main module for deploy complexity that parses output from git
  # and returns information on the deploy
  class Deploy # rubocop:disable Metrics/ClassLength
    # deploys are the delta from base -> to, so to contains commits to add to base

    def initialize(base, to, options)
      @base = base
      @to = to
      @options = options
    end

    def generate
      github = Github.new(options[:gh_url])

      # tag_revision = `git rev-parse --short #{to}`.chomp
      revision = `git rev-list --abbrev-commit -n1 #{to}`.chomp

      time_delta = time_between_deploys(Git.safe_name(base), Git.safe_name(to))

      commits = `git log --oneline #{range}`.split(/\n/)
      merges = get_merges(commits)

      changed_files = get_changed_files(range)

      # TODO: scan for changes to app/jobs and report changes to params
      formatter_attributes = {
        to: to,
        base: base,
        revision: revision,
        commits: commits,
        pull_requests: pull_requests(merges),
        merges: merges,
        shortstat: shortstat,
        dirstat: dirstat,
        stat: stat,
        time_delta: time_delta,
        github: github,
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

      slack(formatter_attributes, options[:slack_channels])

      DeployComplexity::CliOutputFormatter.with(formatter_attributes).format
    end

    private

    attr_reader :base, :to, :options

    def slack(formatter_attributes, channels)
      return if channels.nil? || channels.none?

      log = DeployComplexity::SlackOutputFormatter.with(formatter_attributes).format
      begin
        webhook = ENV['SLACK_WEBHOOK']
        require 'slack-notifier'
        channels.each do |channel|
          notifier = Slack::Notifier.new webhook do
            defaults channel: channel,
                     username: 'DeployComplexity'
          end
          notifier.ping log
        end
      rescue StandardError => e
        warn "Exception thrown while notifying slack!"
        warn e
      end
    end

    # tag format: production-2016-10-22-0103 or $ENV-YYYY-MM-DD-HHmm
    def parse_when(tag)
      tag.match(/-(\d{4}-\d{2}-\d{2}-\d{2}\d{2})/) do |m|
        Time.strptime(m[1], '%Y-%m-%d-%H%M')
      end
    end

    def time_between_deploys(from, to)
      deploy_time = parse_when(to)
      last_time = parse_when(from)

      hours = deploy_time && ((deploy_time - last_time) / (60**2))

      if hours.nil?
        "pending deploy"
      elsif hours < 24
        "after %2.1f %s" % [hours, "hours"]
      else
        "after %2.1f %s" % [(hours / 24), "days"]
      end
    end

    # converts a branch name like master into the closest tag or commit sha
    def reference(name)
      branch = Git.safe_name(name)
      tag = `git tag --points-at #{name} | grep #{branch}`.chomp
      if tag.empty?
        `git rev-parse --short #{branch}`.chomp
      else
        tag
      end
    end

    # TODO: consider moving this to a separate parser and testing
    def pull_requests(merges)
      merges.map do |line|
        line.match(/Auto merge of #(\d+) - ([^,]+)/) do |m|
          {
            pr_number: m[1].to_i,
            joiner: "-",
            name: Git.safe_name(m[2])
          }
        end || line.match(/pull request #(\d+) from (.*)$/) do |m|
          {
            pr_number: m[1].to_i,
            joiner: "-",
            name: Git.safe_name(m[2])
          }
        end || line.match(/(\w+)\s+(.*)\(\#(\d+)\)/) do |m|
          {
            pr_number: m[3].to_i,
            joiner: "S",
            name: m[2]
          }
        end
      end.compact
    end

    def get_merges(commits)
      merges = commits.grep(/Merges|\#\d+/)
      merges.select { |m| makes_changes_to(m) }
    end

    def get_changed_files(range)
      files = `git diff --name-only #{range}`
      filtered = files.split(/\n/).grep(pattern).join('\n')
      DeployComplexity::ChangedFiles.new(filtered)
    end

    def makes_changes_to(merge)
      commithash = merge.split[0]
      commits = `git log -m -1 --name-only --first-parent --pretty="format:" #{commithash}`.split(/\n/)
      commits.any? { |commit| pattern =~ commit }
    end

    def pattern
      @pattern ||= options[:subdir] ? Regexp.new("^#{@options[:subdir]}") : /.*/
    end

    def subdir
      @options[:subdir] ? File.join(gitroot, @options[:subdir]) : ""
    end

    def range
      "#{@base}...#{@to}"
    end

    def shortstat
      `git diff --shortstat --summary #{range} -- #{subdir}`.split(/\n/)
    end

    def dirstat
      `git diff --dirstat=lines,cumulative #{range} -- #{subdir}` if @options[:dirstat]
    end

    def stat
      # TODO: investigate summarizing language / spec content based on file suffix,
      # and possibly per PR, or classify frontend, backend, spec changes
      `git diff --stat #{range} -- #{subdir}` if @options[:stat]
    end

    def gitroot
      `realpath --relative-to . $(git rev-parse --show-toplevel)`.strip
    end
  end
end
