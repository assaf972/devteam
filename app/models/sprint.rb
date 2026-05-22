class Sprint < ApplicationRecord
  belongs_to :project
  has_many :tickets

  enum :status, { planning: 0, active: 1, completed: 2, cancelled: 3 }, default: :planning

  validates :name, presence: true
  validates :start_date, :end_date, presence: true

  scope :active, -> { where(status: :active) }
  scope :current, -> { active.where("start_date <= ? AND end_date >= ?", Date.today, Date.today) }
end
