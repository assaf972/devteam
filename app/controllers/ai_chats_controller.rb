# Chat with AI — an OpenAI-style assistant that loads the current project/sprint,
# tickets, team messages and recent code as context for every reply.
class AiChatsController < ApplicationController
  before_action :load_sessions
  before_action :set_session, only: %i[show message]

  def index
    @session = @sessions.first
  end

  def show; end

  # Start a new chat (optionally with a first message and a project).
  def create
    @session = current_user.ai_chat_sessions.create!(project: default_project, sprint: default_sprint)
    if params[:message].present?
      converse!(@session, params[:message])
    end
    redirect_to ai_chat_path(@session)
  end

  # Send a message in an existing chat → build context, call the LLM, store reply.
  def message
    converse!(@session, params[:message]) if params[:message].present?
    redirect_to ai_chat_path(@session, anchor: "bottom")
  end

  private

  def load_sessions
    @sessions = current_user.ai_chat_sessions.recent.limit(50)
  end

  def set_session
    @session = current_user.ai_chat_sessions.find(params[:id])
  end

  def default_project
    Sprint.active.first&.project || Project.active.first || Project.first
  end

  def default_sprint
    default_project&.sprints&.active&.first
  end

  # Append the user's message, call the local LLM with fresh context, append reply.
  def converse!(session, text)
    session.ai_chat_messages.create!(role: "user", content: text.to_s.strip)
    session.update!(title: text.to_s.strip.truncate(60)) if session.title.blank?

    client  = Ai::OllamaClient.new
    context = Ai::ChatContextService.new(project: session.project, sprint: session.sprint).system_prompt
    history = session.ai_chat_messages.map { |m| { role: m.role, content: m.content } }

    begin
      reply = client.converse(messages: [ { role: "system", content: context } ] + history)
      session.update!(llm_model: client.model)
    rescue Ai::OllamaClient::Error => e
      reply = "⚠️ The local AI is unavailable right now (#{e.message}). Check that Ollama is running on the Mac mini."
    end

    session.ai_chat_messages.create!(role: "assistant", content: reply.presence || "(no response)")
  end
end
