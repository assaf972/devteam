class SprintsController < ApplicationController
  before_action :set_project, only: %i[index new create]
  before_action :set_sprint,  only: %i[show edit update destroy]

  def index
    @sprints = @project.sprints.order(start_date: :desc)
    @active_sprint    = @sprints.active.first
    @planning_sprints = @sprints.planning
    @done_sprints     = @sprints.completed
  end

  def show
    @tickets       = @sprint.tickets.includes(:assignee, :owner).order(:status, :priority)
    # A ticket still needs evaluation/refinement until it has both a story-point
    # estimate and a dev hour estimate. Everything else is considered planned work.
    @refinement_tickets, @assigned_tickets =
      @tickets.partition { |t| t.story_points.blank? || t.dev_estimate_hours.blank? }
    @meetings      = @sprint.meetings.order(:scheduled_at)
    @pull_requests = @sprint.pull_requests.includes(:ticket).order(created_at: :desc)
    @comments      = @sprint.comments.includes(:author).order(:created_at)
    @comment       = Comment.new
  end

  def new
    @sprint = @project.sprints.build(
      start_date: Date.today,
      end_date:   Date.today + 14
    )
  end

  def create
    @sprint = @project.sprints.build(sprint_params)
    if @sprint.save
      redirect_to @sprint, notice: "Sprint created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @sprint.update(sprint_params)
      redirect_to @sprint, notice: "Sprint updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @project = @sprint.project
    @sprint.destroy
    redirect_to project_sprints_path(@project), notice: "Sprint deleted."
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_sprint
    @sprint  = Sprint.find(params[:id])
    @project = @sprint.project
  end

  def sprint_params
    params.require(:sprint).permit(:name, :start_date, :end_date, :status, :goals, :velocity,
                                   :things_to_improve, :things_that_went_right)
  end
end
