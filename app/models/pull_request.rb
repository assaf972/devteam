class PullRequest < ApplicationRecord
  belongs_to :project
  belongs_to :ticket, optional: true

  has_many :comments, as: :commentable

  serialize :files_changed,       coder: JSON
  serialize :pr_comments_data,    coder: JSON
  serialize :latest_test_results, coder: JSON

  enum :status, { open: 0, review: 1, merged: 2, closed: 3 }, default: :open

  validates :title, presence: true
  validates :pr_number, presence: true

  def pr_comments
    Array(pr_comments_data)
  end

  def changed_files
    Array(files_changed)
  end

  def synced?
    synced_at.present?
  end

  def test_files
    changed_files.select { |f| f.match?(/spec|test|_test\.|_spec\./) }
  end

  def source_files
    changed_files.reject { |f| f.match?(/spec|test|_test\.|_spec\./) }
  end
end
