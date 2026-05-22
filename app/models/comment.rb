class Comment < ApplicationRecord
  belongs_to :author, class_name: "User", optional: true
  belongs_to :commentable, polymorphic: true

  validates :body, presence: true
end
