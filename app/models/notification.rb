class Notification < ApplicationRecord
  belongs_to :recipient, polymorphic: true

  serialize :params, coder: JSON

  scope :unread, -> { where(read_at: nil) }
  scope :read,   -> { where.not(read_at: nil) }

  def read?
    read_at.present?
  end

  def mark_read!
    update(read_at: Time.current) unless read?
  end
end
