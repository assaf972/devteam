require 'rails_helper'

RSpec.describe "Projects", type: :request do
  let(:user)    { create(:user) }
  let(:project) { create(:project) }

  before { sign_in user }

  describe "GET /projects" do
    it "returns http success" do
      get projects_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /projects/:id" do
    it "returns http success and shows the project name" do
      get project_path(project)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(project.name)
    end

    it "renders the Tickets panel before the CI Runs panel" do
      get project_path(project)
      expect(response.body.index('id="tickets"')).to be < response.body.index("CI Runs")
    end

    describe "tickets panel filter" do
      let!(:open_ticket)      { create(:ticket, project: project, status: :in_progress, dev_estimate_hours: 5) }
      let!(:done_ticket)      { create(:ticket, project: project, status: :done) }
      let!(:unestimated)      { create(:ticket, project: project, status: :open, dev_estimate_hours: nil) }

      it "defaults to open tickets (excludes completed)" do
        get project_path(project)
        expect(response.body).to include("T-#{open_ticket.id}")
        expect(response.body).not_to include("T-#{done_ticket.id}")
      end

      it "shows completed tickets when filtered" do
        get project_path(project, ticket_filter: "completed")
        expect(response.body).to include("T-#{done_ticket.id}")
        expect(response.body).not_to include("T-#{open_ticket.id}")
      end

      it "shows only tickets awaiting estimation when filtered" do
        get project_path(project, ticket_filter: "needs_estimation")
        expect(response.body).to include("T-#{unestimated.id}")
        expect(response.body).not_to include("T-#{open_ticket.id}")
        expect(response.body).not_to include("T-#{done_ticket.id}")
      end

      it "exposes a quick status-change action per ticket" do
        get project_path(project)
        expect(response.body).to include(update_status_ticket_path(open_ticket, status: "done"))
        expect(response.body).to include(move_to_sprint_ticket_path(open_ticket, target: "backlog"))
      end
    end
  end

  describe "POST /projects" do
    it "creates a project and redirects" do
      expect {
        post projects_path, params: { project: { name: "Brand New Project" } }
      }.to change(Project, :count).by(1)
      expect(response).to redirect_to(project_path(Project.last))
    end

    it "re-renders on invalid params" do
      post projects_path, params: { project: { name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /projects/:id" do
    it "updates the project and redirects" do
      patch project_path(project), params: { project: { name: "Renamed" } }
      expect(response).to redirect_to(project_path(project))
      expect(project.reload.name).to eq("Renamed")
    end
  end
end
