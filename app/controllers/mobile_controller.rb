class MobileController < ApplicationController
  layout "mobile"
  before_action :authenticate_user!

  # ── Today ─────────────────────────────────────────────────────────────────
  def today
    today_range = Time.current.beginning_of_day..Time.current.end_of_day

    @my_active_tickets = current_user.assigned_tickets
                           .where.not(status: %i[done closed])
                           .includes(:project)
                           .order(priority: :desc, updated_at: :desc)
                           .limit(10)

    @meetings_today = Meeting
                        .joins(:meeting_attendees)
                        .where(meeting_attendees: { user_id: current_user.id })
                        .where(scheduled_at: today_range)
                        .where.not(status: :cancelled)
                        .includes(:project, :organizer)
                        .order(:scheduled_at)
                        .or(
                          Meeting.where(organizer: current_user, scheduled_at: today_range)
                                 .where.not(status: :cancelled)
                                 .includes(:project, :organizer)
                                 .order(:scheduled_at)
                        )
                        .distinct

    @next_meeting = @meetings_today.find { |m| m.scheduled_at > Time.current }

    @my_ci_runs_today = CiRun.where(triggered_by: current_user, created_at: today_range)
                               .includes(:project)
                               .order(created_at: :desc)
                               .limit(5)

    @my_failing_builds = CiRun.where(triggered_by: current_user, status: :failed)
                                .includes(:project)
                                .order(created_at: :desc)
                                .limit(3)

    @my_deployments_today = Deployment.where(deployed_by: current_user, created_at: today_range)
                                        .includes(:project)
                                        .order(created_at: :desc)
                                        .limit(5)

    my_project_ids = current_user.assigned_tickets.select(:project_id).distinct
    @recent_prs = PullRequest.where(project_id: my_project_ids, status: :open)
                               .order(updated_at: :desc)
                               .limit(5)

    @summary = {
      active_tickets:  @my_active_tickets.size,
      meetings_today:  @meetings_today.size,
      ci_runs_today:   @my_ci_runs_today.size,
      failing_builds:  @my_failing_builds.size,
      deploys_today:   @my_deployments_today.size,
      open_prs:        @recent_prs.size
    }
  end

  # ── Messages ──────────────────────────────────────────────────────────────
  def messages
    @chat_rooms = ChatRoom.includes(:chat_messages)
                          .order(updated_at: :desc)
  end

  # ── Meetings ──────────────────────────────────────────────────────────────
  def meetings
    @upcoming = Meeting
                  .joins(:meeting_attendees)
                  .where(meeting_attendees: { user_id: current_user.id })
                  .where("scheduled_at >= ?", Time.current)
                  .where.not(status: :cancelled)
                  .includes(:project, :organizer)
                  .order(:scheduled_at)
                  .or(
                    Meeting.where(organizer: current_user)
                           .where("scheduled_at >= ?", Time.current)
                           .where.not(status: :cancelled)
                           .includes(:project, :organizer)
                           .order(:scheduled_at)
                  )
                  .distinct
                  .limit(20)

    @past = Meeting
              .joins(:meeting_attendees)
              .where(meeting_attendees: { user_id: current_user.id })
              .where("scheduled_at < ?", Time.current)
              .includes(:project, :organizer)
              .order(scheduled_at: :desc)
              .or(
                Meeting.where(organizer: current_user)
                       .where("scheduled_at < ?", Time.current)
                       .includes(:project, :organizer)
                       .order(scheduled_at: :desc)
              )
              .distinct
              .limit(10)
  end

  # ── Projects ──────────────────────────────────────────────────────────────
  def projects
    @projects = Project.includes(:tickets, :sprints)
                       .order(updated_at: :desc)
  end

  # ── Tickets ───────────────────────────────────────────────────────────────
  def tickets
    @my_tickets = current_user.assigned_tickets
                               .includes(:project, :sprint)
                               .order(priority: :desc, updated_at: :desc)

    @open       = @my_tickets.where.not(status: %i[done closed])
    @done       = @my_tickets.where(status: %i[done closed]).limit(10)
  end

  # ── Video Calls ───────────────────────────────────────────────────────────
  def video_calls
    @upcoming_video = Meeting
                        .joins(:meeting_attendees)
                        .where(meeting_attendees: { user_id: current_user.id })
                        .where("scheduled_at >= ?", Time.current)
                        .where.not(status: :cancelled)
                        .includes(:project, :organizer)
                        .order(:scheduled_at)
                        .or(
                          Meeting.where(organizer: current_user)
                                 .where("scheduled_at >= ?", Time.current)
                                 .where.not(status: :cancelled)
                                 .includes(:project, :organizer)
                                 .order(:scheduled_at)
                        )
                        .distinct
                        .limit(10)

    @active_video = @upcoming_video.select { |m| m.status.to_s == "in_progress" }
  end
end
