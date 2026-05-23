class ProjectsController < ApplicationController
  before_action :set_project, only: [ :show, :edit, :update, :destroy, :report, :ci_dashboard, :calendar_events ]

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
    @recent_ci_runs     = @project.ci_runs.includes(:triggered_by).order(created_at: :desc).limit(5)
    @recent_deployments = @project.deployments.includes(:deployed_by).order(created_at: :desc).limit(5)
    @open_pull_requests = @project.pull_requests.where(status: :open).order(updated_at: :desc).limit(5)
    @recent_documents   = @project.documents.order(updated_at: :desc).limit(6)
    @open_tickets       = @project.tickets.where.not(status: [ :done, :closed ]).includes(:assignee).order(updated_at: :desc).limit(8)
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

  # GET /projects/:id/calendar_events.json
  def calendar_events
    range_start = params[:start]&.to_datetime
    range_end   = params[:end]&.to_datetime
    events = []

    # Meetings
    meetings = @project.meetings
    meetings = meetings.where(scheduled_at: range_start..range_end) if range_start && range_end
    meetings.each do |m|
      duration = (m.duration_minutes || 60).minutes
      events << {
        id:    "meeting-#{m.id}",
        title: m.title,
        start: m.scheduled_at&.iso8601,
        end:   m.scheduled_at ? (m.scheduled_at + duration).iso8601 : nil,
        url:   meeting_path(m),
        color: "#4a90d9",
        extendedProps: { type: "meeting" }
      }
    end

    # Milestones
    milestones = @project.milestones
    milestones = milestones.where(due_date: range_start..range_end) if range_start && range_end
    milestones.each do |ms|
      events << {
        id:    "milestone-#{ms.id}",
        title: "🏁 #{ms.name}",
        start: ms.due_date&.iso8601,
        allDay: true,
        url:   project_path(@project),
        color: "#e84545",
        extendedProps: { type: "milestone" }
      }
    end

    # Sprints
    @project.sprints.each do |s|
      next unless s.start_date.present? && s.end_date.present?
      next if range_start && s.end_date < range_start.to_date
      next if range_end   && s.start_date > range_end.to_date

      events << {
        id:    "sprint-#{s.id}",
        title: "⚡ #{s.name}",
        start: s.start_date.iso8601,
        end:   (s.end_date + 1.day).iso8601,
        allDay: true,
        url:   sprint_path(s),
        color: "#38c96d",
        display: "background",
        extendedProps: { type: "sprint" }
      }
    end

    render json: events
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :description, :repo_url, :tech_stack, :gitea_repo_id, :default_branch, :active)
  end
end
