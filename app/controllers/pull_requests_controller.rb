class PullRequestsController < ApplicationController
  before_action :set_project, only: [ :index ]
  before_action :set_pull_request, only: [ :show, :sync ]

  def index
    @pull_requests = @project.pull_requests
                              .includes(:ticket)
                              .order(updated_at: :desc)
    @pull_requests = @pull_requests.where(status: params[:status]) if params[:status].present?
  end

  def show; end

  def sync
    SyncPullRequestJob.perform_later(@pull_request.id)
    redirect_to @pull_request, notice: "Sync started — data will refresh in a moment."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_pull_request
    @pull_request = PullRequest.find(params[:id])
    @project = @pull_request.project
  end
end
