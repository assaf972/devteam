class Deployment < ApplicationRecord
  belongs_to :project
  belongs_to :deployed_by, class_name: "User", optional: true
  belongs_to :client_account, optional: true
  has_many :installations

  enum :status, { pending: 0, in_progress: 1, succeeded: 2, failed: 3, rolled_back: 4 }, default: :pending
  enum :deploy_type, { web_app: 0, windows_installer: 1, windows_service: 2, docker: 3 }, default: :web_app

  validates :version, :environment, presence: true
end
