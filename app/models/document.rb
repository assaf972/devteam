class Document < ApplicationRecord
  belongs_to :project
  belongs_to :author, class_name: "User", optional: true

  has_many :comments, as: :commentable
  has_one_attached :attachment

  acts_as_taggable_on :tags

  enum :doc_type, {
    spec: 0, risk_management: 1, user_story: 2, timeline: 3,
    test_coverage: 4, architecture: 5, runbook: 6, other: 7
  }, default: :other

  validates :title, :content, presence: true
end
