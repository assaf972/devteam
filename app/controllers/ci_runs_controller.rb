class CiRunsController < ApplicationController
  before_action :set_project

  def index
    @ci_runs = @project.ci_runs
                       .includes(:triggered_by, :test_results)
                       .order(created_at: :desc)
                       .limit(50)
  end

  def show
    @ci_run = @project.ci_runs.find(params[:id])
    @test_results = @ci_run.test_results
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end
end
