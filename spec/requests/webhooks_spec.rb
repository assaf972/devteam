require 'rails_helper'

RSpec.describe "Webhooks", type: :request do
  describe "GET /gitea" do
    it "returns http success" do
      get "/webhooks/gitea"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /jenkins" do
    it "returns http success" do
      get "/webhooks/jenkins"
      expect(response).to have_http_status(:success)
    end
  end

end
