require 'rails_helper'

RSpec.describe "Reports", type: :request do
  describe "GET /ci_summary" do
    it "returns http success" do
      get "/reports/ci_summary"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /deployment_summary" do
    it "returns http success" do
      get "/reports/deployment_summary"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /test_coverage" do
    it "returns http success" do
      get "/reports/test_coverage"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /sprint_velocity" do
    it "returns http success" do
      get "/reports/sprint_velocity"
      expect(response).to have_http_status(:success)
    end
  end

end
