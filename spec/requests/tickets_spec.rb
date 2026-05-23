require 'rails_helper'

RSpec.describe "Tickets", type: :request do
  let(:user)    { create(:user) }
  let(:project) { create(:project) }
  let!(:ticket) { create(:ticket, project: project) }

  before { sign_in user }

  # ── GET /projects/:project_id/tickets ─────────────────────────────────────
  describe "GET /projects/:project_id/tickets" do
    it "returns http success" do
      get project_tickets_path(project)
      expect(response).to have_http_status(:success)
    end

    it "displays the project name" do
      get project_tickets_path(project)
      expect(response.body).to include(project.name)
    end
  end

  # ── GET /tickets/:id ──────────────────────────────────────────────────────
  describe "GET /tickets/:id" do
    it "returns http success" do
      get ticket_path(ticket)
      expect(response).to have_http_status(:success)
    end

    it "displays the ticket title" do
      get ticket_path(ticket)
      expect(response.body).to include(ticket.title)
    end
  end

  # ── GET /projects/:project_id/tickets/new ─────────────────────────────────
  describe "GET /projects/:project_id/tickets/new" do
    it "returns http success" do
      get new_project_ticket_path(project)
      expect(response).to have_http_status(:success)
    end
  end

  # ── POST /projects/:project_id/tickets ────────────────────────────────────
  describe "POST /projects/:project_id/tickets" do
    context "with valid params" do
      it "creates a ticket and redirects" do
        expect {
          post project_tickets_path(project), params: {
            ticket: { title: "New ticket", status: "open", priority: "medium" }
          }
        }.to change(Ticket, :count).by(1)
        expect(response).to redirect_to(ticket_path(Ticket.last))
      end
    end

    context "with invalid params (blank title)" do
      it "re-renders the form with unprocessable_entity" do
        post project_tickets_path(project), params: {
          ticket: { title: "" }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # ── GET /tickets/:id/edit ─────────────────────────────────────────────────
  describe "GET /tickets/:id/edit" do
    it "returns http success" do
      get edit_ticket_path(ticket)
      expect(response).to have_http_status(:success)
    end
  end

  # ── PATCH /tickets/:id ────────────────────────────────────────────────────
  describe "PATCH /tickets/:id" do
    context "with valid params" do
      it "updates the ticket and redirects" do
        patch ticket_path(ticket), params: {
          ticket: { title: "Updated title", status: "in_progress" }
        }
        expect(response).to redirect_to(ticket_path(ticket))
        expect(ticket.reload.title).to eq("Updated title")
        expect(ticket.reload.status).to eq("in_progress")
      end
    end

    context "updating estimate fields" do
      it "updates dev and QA estimates" do
        patch ticket_path(ticket), params: {
          ticket: { dev_estimate_hours: "4.5", tester_estimate_hours: "2.0" }
        }
        expect(ticket.reload.dev_estimate_hours).to eq(4.5)
        expect(ticket.reload.tester_estimate_hours).to eq(2.0)
      end
    end

    context "with invalid params" do
      it "re-renders the form" do
        patch ticket_path(ticket), params: { ticket: { title: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # ── DELETE /tickets/:id ───────────────────────────────────────────────────
  describe "DELETE /tickets/:id" do
    it "destroys the ticket and redirects to project tickets" do
      expect {
        delete ticket_path(ticket)
      }.to change(Ticket, :count).by(-1)
      expect(response).to redirect_to(project_tickets_path(project))
    end
  end

  # ── Comments ──────────────────────────────────────────────────────────────
  describe "POST /tickets/:ticket_id/comments" do
    context "when user is an admin" do
      let(:user) { create(:user, role: :admin) }

      it "creates a comment and redirects back to ticket" do
        post ticket_comments_path(ticket), params: { comment: { body: "Great work!" } }
        expect(response).to redirect_to(ticket_path(ticket))
        expect(ticket.comments.last.body).to eq("Great work!")
      end

      it "rejects blank comments" do
        post ticket_comments_path(ticket), params: { comment: { body: "" } }
        expect(response).to redirect_to(ticket_path(ticket))
        expect(flash[:alert]).to include("blank")
      end
    end
  end
end
