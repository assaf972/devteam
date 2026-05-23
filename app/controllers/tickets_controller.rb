class TicketsController < ApplicationController
  before_action :set_project, only: [ :index, :new, :create ]
  before_action :set_ticket,  only: [ :show, :edit, :update, :destroy ]

  def index
    @tickets = @project.tickets.includes(:assignee, :sprint, :ci_runs).order(priority: :desc, created_at: :desc)
    @tickets = @tickets.where(status: params[:status]) if params[:status].present?
    @tickets = @tickets.where(assignee: current_user) if params[:mine] == "true"
    @tickets = @tickets.tagged_with(params[:tag]) if params[:tag].present?
  end

  def show
    @comments   = @ticket.comments.includes(:author).order(created_at: :asc)
    @ci_runs    = @ticket.ci_runs.includes(:test_results).order(created_at: :desc).limit(10)
    @branches   = @ticket.branches
    @pull_requests = @ticket.pull_requests
  end

  def new
    @ticket = @project.tickets.build
  end

  def create
    @ticket = @project.tickets.build(ticket_params)

    if @ticket.save
      TicketNotificationJob.perform_later(@ticket.id, "created") if defined?(TicketNotificationJob)
      redirect_to @ticket, notice: t("tickets.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    old_assignee_id = @ticket.assignee_id
    if @ticket.update(ticket_params)
      # Auto-create branch when ticket is assigned for the first time
      if @ticket.assignee_id.present? && old_assignee_id != @ticket.assignee_id
        CreateBranchJob.perform_later(@ticket.id) if defined?(CreateBranchJob)
        TicketMailer.assigned(@ticket).deliver_later
      end
      # Notify watchers on status change
      if @ticket.saved_change_to_status?
        @ticket.watchers.each { |w| TicketMailer.status_changed(@ticket, w).deliver_later }
      end
      redirect_to @ticket, notice: t("tickets.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @ticket.destroy
    redirect_to project_tickets_path(@project), notice: t("tickets.deleted")
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_ticket
    @ticket  = Ticket.find(params[:id])
    @project = @ticket.project
  end

  def ticket_params
    params.require(:ticket).permit(
      :title, :description, :status, :priority, :kind, :level,
      :how_to_reproduce, :sprint_id, :assignee_id, :owner_id,
      :milestone_id, :story_points, :tag_list, :pr_number, :pr_url,
      :dev_estimate_hours, :tester_estimate_hours,
      attachments: []
    )
  end
end
