class Ticket < ApplicationRecord
  belongs_to :project
  belongs_to :sprint, optional: true
  belongs_to :assignee, class_name: "User", optional: true
  belongs_to :owner, class_name: "User", optional: true
  belongs_to :milestone, optional: true

  has_many :comments, as: :commentable
  has_many :branches
  has_many :pull_requests
  has_many :ci_runs
  has_many :ticket_watchers
  has_many :watchers, through: :ticket_watchers, source: :user
  has_many :test_results, through: :ci_runs

  has_many_attached :attachments

  acts_as_taggable_on :tags, :labels

  enum :kind, {
    story: 0, meta_story: 1, bug_fix: 2, spike: 3, hotfix: 4
  }, default: :story

  enum :level, {
    trivial: 0, simple: 1, moderate: 2, complex: 3, expert: 4
  }, default: :moderate

  enum :status, {
    backlog: 0, open: 1, in_progress: 2, in_review: 3,
    testing: 4, done: 5, closed: 6, blocked: 7
  }, default: :backlog

  enum :priority, { low: 0, medium: 1, high: 2, critical: 3 }, default: :medium

  validates :title, presence: true
  validates :project, presence: true

  after_save :auto_create_branch_and_notify,
             if: -> { saved_change_to_assignee_id? && assignee_id.present? }

  def latest_ci_run
    ci_runs.order(created_at: :desc).first
  end

  def branch_name_for_ticket
    prefix = (bug_fix? || hotfix?) ? "bugfix" : "feature"
    "#{prefix}/T-#{id}-#{title.parameterize.first(50)}"
  end

  def bug_kind?
    bug_fix? || hotfix?
  end

  private

  def auto_create_branch_and_notify
    TicketBranchService.new(self).call
  end
end
