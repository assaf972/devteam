class Sprint < ApplicationRecord
  belongs_to :project

  has_many :tickets
  has_many :meetings
  has_many :pull_requests, through: :tickets
  has_many :comments, as: :commentable, dependent: :destroy
  has_many :ai_reviews, as: :reviewable, dependent: :destroy

  enum :status, { planning: 0, active: 1, completed: 2, cancelled: 3 }, default: :planning

  validates :name, presence: true
  validates :start_date, :end_date, presence: true
  validate :end_date_after_start_date

  scope :active,    -> { where(status: :active) }
  scope :planning,  -> { where(status: :planning) }
  scope :completed, -> { where(status: :completed) }
  scope :current,   -> { active.where("start_date <= ? AND end_date >= ?", Date.today, Date.today) }
  scope :upcoming,  -> { where("start_date > ?", Date.today).order(:start_date) }

  def duration_days
    (end_date - start_date).to_i
  end

  def days_remaining
    [ (end_date - Date.today).to_i, 0 ].max
  end

  def progress_percent
    total = tickets.count
    return 0 if total.zero?
    done = tickets.where(status: %i[done closed]).count
    (done * 100.0 / total).round
  end

  private

  def end_date_after_start_date
    return unless start_date && end_date
    errors.add(:end_date, "must be after start date") if end_date < start_date
  end
end
