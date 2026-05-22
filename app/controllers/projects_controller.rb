class ProjectsController < ApplicationController
  before_action :set_project, only: [ :show, :edit, :update, :destroy, :report, :ci_dashboard ]

  def index
    @projects = Project.order(:name)
  end

  def show
    ticket_ids = @project.tickets.select(:id)
    @recent_comments = Comment
                         .includes(:author, :commentable)
                         .where(commentable_type: "Ticket", commentable_id: ticket_ids)
                         .order(created_at: :desc)
                         .limit(8)
  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(project_params)
    if @project.save
      redirect_to @project, notice: "Project created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @project.update(project_params)
      redirect_to @project, notice: "Project updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project.destroy
    redirect_to projects_path, notice: "Project deleted."
  end

  def report
    @sprint_stats = @project.sprints.includes(:tickets)
    @test_summary = @project.ci_runs.includes(:test_results)
  end

  def ci_dashboard
    @ci_runs = @project.ci_runs.includes(:triggered_by, :test_results, :ticket)
                        .order(created_at: :desc).limit(100)
    render "ci_runs/index"
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description, :repo_url, :tech_stack, :gitea_repo_id, :default_branch, :active)
  end
end
