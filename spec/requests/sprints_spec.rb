require 'rails_helper'

RSpec.describe "Sprints", type: :request do
  let(:user)    { create(:user) }
  let(:project) { create(:project) }
  let!(:sprint) { create(:sprint, project: project) }

  before { sign_in user }

  # ── GET /projects/:project_id/sprints ─────────────────────────────────────
  describe "GET /projects/:project_id/sprints" do
    it "returns http success" do
      get project_sprints_path(project)
      expect(response).to have_http_status(:success)
    end

    it "displays the sprint name" do
      get project_sprints_path(project)
      expect(response.body).to include(sprint.name)
    end

    it "shows active sprint banner when present" do
      active = create(:active_sprint, project: project)
      get project_sprints_path(project)
      expect(response.body).to include("Active Sprint")
      expect(response.body).to include(active.name)
    end
  end

  # ── GET /sprints/:id ──────────────────────────────────────────────────────
  describe "GET /sprints/:id" do
    it "returns http success" do
      get sprint_path(sprint)
      expect(response).to have_http_status(:success)
    end

    it "displays sprint details" do
      get sprint_path(sprint)
      expect(response.body).to include(sprint.name)
      expect(response.body).to include(sprint.start_date.strftime("%d %b %Y"))
    end

    it "shows linked tickets" do
      ticket = create(:ticket, project: project, sprint: sprint)
      get sprint_path(sprint)
      expect(response.body).to include(ticket.title)
    end

    it "shows linked meetings" do
      meeting = create(:meeting, project: project, sprint: sprint,
                        scheduled_at: 1.day.from_now, title: "Sprint Planning")
      get sprint_path(sprint)
      expect(response.body).to include("Sprint Planning")
    end

    it "shows progress percentage" do
      done_ticket = create(:ticket, project: project, sprint: sprint, status: :done)
      get sprint_path(sprint)
      expect(response.body).to match(/\d+%/)
    end
  end

  # ── GET /projects/:project_id/sprints/new ─────────────────────────────────
  describe "GET /projects/:project_id/sprints/new" do
    it "returns http success" do
      get new_project_sprint_path(project)
      expect(response).to have_http_status(:success)
    end
  end

  # ── POST /projects/:project_id/sprints ────────────────────────────────────
  describe "POST /projects/:project_id/sprints" do
    let(:valid_params) do
      { sprint: { name: "Sprint 2", start_date: Date.today,
                  end_date: Date.today + 14, status: :planning, velocity: 30 } }
    end

    context "with valid params" do
      it "creates a sprint and redirects to show" do
        expect {
          post project_sprints_path(project), params: valid_params
        }.to change(Sprint, :count).by(1)
        expect(response).to redirect_to(sprint_path(Sprint.last))
      end
    end

    context "with invalid params" do
      it "re-renders new when name is blank" do
        post project_sprints_path(project), params: { sprint: { name: "", start_date: Date.today, end_date: Date.today + 7 } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "re-renders new when end_date is before start_date" do
        post project_sprints_path(project), params: { sprint: { name: "Bad", start_date: Date.today, end_date: Date.today - 1 } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  # ── GET /sprints/:id/edit ─────────────────────────────────────────────────
  describe "GET /sprints/:id/edit" do
    it "returns http success" do
      get edit_sprint_path(sprint)
      expect(response).to have_http_status(:success)
    end
  end

  # ── PATCH /sprints/:id ────────────────────────────────────────────────────
  describe "PATCH /sprints/:id" do
    it "updates and redirects to show" do
      patch sprint_path(sprint), params: { sprint: { name: "Updated Sprint", end_date: sprint.end_date } }
      expect(response).to redirect_to(sprint_path(sprint))
      expect(sprint.reload.name).to eq("Updated Sprint")
    end

    it "re-renders edit on invalid data" do
      patch sprint_path(sprint), params: { sprint: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  # ── DELETE /sprints/:id ───────────────────────────────────────────────────
  describe "DELETE /sprints/:id" do
    it "destroys the sprint and redirects to project sprints" do
      expect {
        delete sprint_path(sprint)
      }.to change(Sprint, :count).by(-1)
      expect(response).to redirect_to(project_sprints_path(project))
    end
  end

  # ── Sprint comments ───────────────────────────────────────────────────────
  describe "POST /sprints/:sprint_id/comments" do
    it "creates a comment" do
      expect {
        post sprint_comments_path(sprint), params: { comment: { body: "Great progress!" } }
      }.to change(Comment, :count).by(1)
      expect(response).to redirect_to(sprint_path(sprint))
    end

    it "rejects blank comments" do
      expect {
        post sprint_comments_path(sprint), params: { comment: { body: "" } }
      }.not_to change(Comment, :count)
    end
  end

  # ── Unauthenticated access ────────────────────────────────────────────────
  describe "when not signed in" do
    before { sign_out user }

    it "redirects to sign-in" do
      get project_sprints_path(project)
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
