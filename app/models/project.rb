class Project < ApplicationRecord
  has_many :sprints
  has_many :milestones
  has_many :tickets
  has_many :ci_runs
  has_many :deployments
  has_many :documents
  has_many :meetings
  has_many :pull_requests
  has_many :branches
  has_many :installations
  has_many :project_memberships, dependent: :destroy
  has_many :members, through: :project_memberships, source: :user
  has_many :activities, dependent: :destroy

  validates :name, presence: true

  scope :active, -> { where(active: true) }
end
