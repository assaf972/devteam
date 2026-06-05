require 'rails_helper'

RSpec.describe "AiChats", type: :request do
  let(:user)    { create(:user) }
  let!(:project) { create(:project) }
  before { sign_in user }

  describe "GET /ai_chats" do
    it "renders the chat page with the new-chat input and doc recommendations" do
      get ai_chats_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Chat with AI")
      expect(response.body).to include("Generate a specification")
      expect(response.body).to include('data-controller="ai-chat"')
    end
  end

  describe "POST /ai_chats (new chat with a first message)" do
    it "creates a session, stores the exchange and replies using context" do
      allow_any_instance_of(Ai::OllamaClient).to receive(:converse).and_return("Here is the spec…")

      expect {
        post ai_chats_path, params: { message: "Generate a spec" }
      }.to change(AiChatSession, :count).by(1)

      session = AiChatSession.last
      expect(session.ai_chat_messages.pluck(:role)).to eq(%w[user assistant])
      expect(session.ai_chat_messages.last.content).to include("Here is the spec")
      expect(session.title).to eq("Generate a spec")
      expect(response).to redirect_to(ai_chat_path(session))
    end
  end

  describe "POST /ai_chats/:id/message" do
    let(:session) { user.ai_chat_sessions.create!(project: project) }

    it "appends the reply from the local LLM" do
      allow_any_instance_of(Ai::OllamaClient).to receive(:converse).and_return("The sprint is on track.")
      expect {
        post message_ai_chat_path(session), params: { message: "How is the sprint?" }
      }.to change { session.ai_chat_messages.count }.by(2)
      expect(session.ai_chat_messages.last.content).to include("on track")
    end

    it "degrades gracefully when the LLM is offline" do
      allow_any_instance_of(Ai::OllamaClient).to receive(:converse)
        .and_raise(Ai::OllamaClient::Error, "connection refused")
      post message_ai_chat_path(session), params: { message: "hi" }
      expect(session.ai_chat_messages.last.content).to match(/unavailable/i)
    end

    it "does not leak another user's session" do
      other = create(:user).ai_chat_sessions.create!
      post message_ai_chat_path(other), params: { message: "hi" }
      expect(response).to have_http_status(:not_found)
      expect(other.ai_chat_messages).to be_empty
    end
  end

  describe "context service" do
    it "includes project, tickets and sprint context" do
      sprint = create(:active_sprint, project: project, name: "Sprint X")
      create(:ticket, project: project, sprint: sprint, title: "Build login")
      ctx = Ai::ChatContextService.new(project: project, sprint: sprint).context_body
      expect(ctx).to include(project.name)
      expect(ctx).to include("Sprint X")
      expect(ctx).to include("Build login")
    end
  end
end
