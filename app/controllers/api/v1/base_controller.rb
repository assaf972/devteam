module Api
  module V1
    class BaseController < ApplicationController
      protect_from_forgery with: :null_session
      before_action :authenticate_api_user!

      private

      def authenticate_api_user!
        token = request.headers["Authorization"]&.sub(/\ABearer\s+/, "")
        @current_api_user = User.find_by(api_token: token) if token.present?
        render json: { error: "Unauthorized" }, status: :unauthorized unless @current_api_user
      end

      def current_api_user
        @current_api_user
      end

      def render_ticket(ticket)
        {
          id:                    ticket.id,
          title:                 ticket.title,
          description:           ticket.description,
          status:                ticket.status,
          priority:              ticket.priority,
          kind:                  ticket.kind,
          level:                 ticket.level,
          how_to_reproduce:      ticket.how_to_reproduce,
          pr_number:             ticket.pr_number,
          pr_url:                ticket.pr_url,
          dev_estimate_hours:    ticket.dev_estimate_hours,
          tester_estimate_hours: ticket.tester_estimate_hours,
          project: {
            id:   ticket.project_id,
            name: ticket.project.name,
            repo_url: ticket.project.repo_url,
            default_branch: ticket.project.default_branch
          },
          assignee: ticket.assignee && { id: ticket.assignee_id, name: ticket.assignee.display_name },
          owner:    ticket.owner    && { id: ticket.owner_id,    name: ticket.owner.display_name },
          branch_name: ticket.branch_name,
          created_at: ticket.created_at,
          updated_at: ticket.updated_at
        }
      end
    end
  end
end
