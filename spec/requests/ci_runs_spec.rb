require 'rails_helper'

RSpec.describe "CiRuns", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/ci_runs/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/ci_runs/show"
      expect(response).to have_http_status(:success)
    end
  end

end
