# A unit of work under a ticket. Breaking a story into tasks makes estimation
# easier and lets us derive a story's progress from how many tasks are complete.
# Status is derived from the started_at / completed_at timestamps.
class Task < ApplicationRecord
  belongs_to :ticket
  belongs_to :user, optional: true

  validates :description, presence: true

  scope :completed,   -> { where.not(completed_at: nil) }
  scope :in_progress, -> { where.not(started_at: nil).where(completed_at: nil) }
  scope :not_started, -> { where(started_at: nil, completed_at: nil) }
  scope :ordered,     -> { order(:created_at) }

  def status
    return "completed"   if completed_at.present?
    return "in_progress" if started_at.present?
    "not_started"
  end

  def completed?
    completed_at.present?
  end

  def start!
    return if completed?
    update!(started_at: started_at || Time.current)
  end

  def complete!
    update!(started_at: started_at || Time.current, completed_at: Time.current)
  end

  def reopen!
    update!(completed_at: nil)
  end

  STATUS_BADGES = {
    "not_started" => "bg-secondary",
    "in_progress" => "bg-info text-dark",
    "completed"   => "bg-success"
  }.freeze

  def status_badge_class
    STATUS_BADGES.fetch(status, "bg-secondary")
  end
end
