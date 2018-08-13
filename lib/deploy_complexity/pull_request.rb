# frozen_string_literal: true

require 'octokit'

# represent a pull request for the purposes of adding checklist items to it.
class PullRequest
  def initialize(client, org, repo, branch)
    @client = client
    @org = org
    @repo = repo
    @branch = branch
  end

  def present?
    !pr.nil?
  end

  def update_with_checklists(checklists)
    added = append_checklists(checklists)
    add_checklist_comment(checklists) if added

    added
  end

  def to_s
    "https://github.com/#{org_and_repo}/pulls/#{number}"
  end

  def base
    pr&.base&.sha
  end

  def head
    pr&.head&.sha
  end

  private

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

  def number
    pr&.number
  end

  def pr
    @pr ||=
      @client
      .pull_requests(org_and_repo, head: "#{@org}:#{@branch}")
      .first
  end

  def add_comment(comment)
    return if pr.nil?
    @client.add_comment(org_and_repo, number, comment)
  end

  def org_and_repo
    "#{@org}/#{@repo}"
  end

  def body_with_checklist(checklists)
    body = pr.body.clone

    checklists.each do |checklist|
      body += checklist.for_pr_body
    end

    body
  end
end
