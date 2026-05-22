module Api
  module V1
    class TicketsController < BaseController
      before_action :set_ticket, only: %i[show update]

      # GET /api/v1/tickets
      # ?status=open&project_id=1&assignee=me
      def index
        scope = Ticket.includes(:project, :assignee, :owner)

        scope = scope.where(assignee: current_api_user) if params[:assignee] == "me"
        scope = scope.where(project_id: params[:project_id]) if params[:project_id].present?
        scope = scope.where(status: params[:status])         if params[:status].present?
        scope = scope.where(priority: params[:priority])     if params[:priority].present?

        tickets = scope.order(updated_at: :desc).limit(100)
        render json: tickets.map { |t| render_ticket(t) }
      end

      # GET /api/v1/tickets/:id
      def show
        render json: render_ticket(@ticket)
      end

      # PATCH /api/v1/tickets/:id
      def update
        allowed = %w[status priority assignee_id pr_number pr_url]
        attrs   = params.require(:ticket).permit(*allowed)

        if @ticket.update(attrs)
          render json: render_ticket(@ticket)
        else
          render json: { errors: @ticket.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_ticket
        @ticket = Ticket.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Ticket not found" }, status: :not_found
      end
    end
  end
end
