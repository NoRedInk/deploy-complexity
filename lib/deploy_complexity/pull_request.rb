# frozen_string_literal: true
require 'octokit'

# represent a pull request for the purposes of adding checklist items to it.
class PullRequest
  def initialize(branch, org = "NoRedInk", repo = "NoRedInk", token = nil)
    @branch = branch
    @client = Octokit::Client.new(access_token: token || ENV['GITHUB_TOKEN'])
    @org = org
    @repo = repo
  end

  def org_and_repo
    "#{@org}/#{@repo}"
  end

  def add_comment(comment)
    return if pr.nil?
    @client.add_comment(org_and_repo, number, comment)
  end

  def append_checklists(checklists)
    return [] if pr.nil?
    new_checklists =
      checklists.reject { |checklist| pr.body.include? checklist.id }

    unless checklists.empty?
      new_body = body_with_checklist(new_checklists)
      @client.update_issue(org_and_repo, number, body: new_body)
      @pr = nil
    end

    new_checklists
  end

  # disable line length because GFM dislikes newlines--it interprets them
  # literally leading to weird-looking comments.
  # rubocop:disable Metrics/LineLength
  def add_checklist_comment(checklists)
    checklist_str = checklists.length == 1 ? "a checklist" : "some checklists"
    comments = "Hey! I added #{checklist_str} because you modified some special files. Please look at the updated pull request body and make sure you check off any new items."

    add_comment(comments)
  end
  # rubocop:enable Metrics/LineLength

  def base
    pr&.base&.sha
  end

  def head
    pr&.head&.sha
  end

  def present?
    !pr.nil?
  end

  def number
    pr.try(:number)
  end

  private

  def pr
    @pr ||=
      @client
      .pull_requests(org_and_repo, head: "#{@org}:#{@branch}")
      .first
  end

  def body_with_checklist(checklists)
    body = pr.body.clone

    checklists.each do |checklist|
      body += checklist.for_pr_body
    end

    body
  end
end
