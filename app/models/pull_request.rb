class PullRequest < ApplicationRecord
  belongs_to :project
  belongs_to :ticket, optional: true

  has_many :comments, as: :commentable

  enum :status, { open: 0, review: 1, merged: 2, closed: 3 }, default: :open

  validates :title, presence: true
  validates :pr_number, presence: true
end
