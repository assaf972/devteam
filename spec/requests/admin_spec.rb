require 'rails_helper'

RSpec.describe "Admins", type: :request do
  describe "GET /users" do
    it "returns http success" do
      get "/admin/users"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /client_accounts" do
    it "returns http success" do
      get "/admin/client_accounts"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /settings" do
    it "returns http success" do
      get "/admin/settings"
      expect(response).to have_http_status(:success)
    end
  end

end
