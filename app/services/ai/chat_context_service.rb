module Ai
  # Builds the system prompt for the Chat with AI page from the current state of
  # a project/sprint: tickets, tasks, recent team messages, documents, and recent
  # code changes (PR diffs). Sizes are capped to keep the prompt manageable.
  class ChatContextService
    def initialize(project: nil, sprint: nil)
      @project = project || sprint&.project
      @sprint  = sprint  || @project&.sprints&.active&.first
    end

    def system_prompt
      <<~SYS
        You are DevTeam Hub's project assistant. Answer using the live project
        context below. Be concise and practical. When asked to produce a document
        (specification, risk management, test plan, etc.), return well-structured
        GitHub-flavored Markdown. If something isn't in the context, say so.

        ===== PROJECT CONTEXT =====
        #{context_body}
        ===== END CONTEXT =====
      SYS
    end

    def context_body
      return "No project selected." if @project.nil?

      [
        project_section,
        sprint_section,
        tickets_section,
        documents_section,
        messages_section,
        code_section
      ].compact.join("\n\n")
    end

    private

    def project_section
      <<~TXT.strip
        Project: #{@project.name}
        Tech stack: #{@project.tech_stack}
        Description: #{@project.description.to_s.truncate(400)}
      TXT
    end

    def sprint_section
      return "Active sprint: none." unless @sprint

      "Active sprint: #{@sprint.name} (#{@sprint.status}, #{@sprint.progress_percent}% done, " \
        "#{@sprint.days_remaining} days remaining). Goal: #{@sprint.goals.to_s.truncate(200)}"
    end

    def tickets_section
      scope   = @sprint ? @sprint.tickets : @project.tickets
      tickets = scope.includes(:assignee).order(updated_at: :desc).limit(25)
      return nil if tickets.empty?

      lines = tickets.map do |t|
        "- T-#{t.id} [#{t.status}] (#{t.priority}, pts #{t.story_points || '—'}) " \
          "#{t.title.truncate(70)} — #{t.assignee&.display_name || 'unassigned'}"
      end
      "Tickets:\n#{lines.join("\n")}"
    end

    def documents_section
      docs = @project.documents.order(updated_at: :desc).limit(10)
      return nil if docs.empty?

      "Documents: #{docs.map { |d| "#{d.title} (#{d.doc_type})" }.join('; ')}"
    end

    def messages_section
      rooms = @project.try(:chat_rooms)
      return nil if rooms.blank?

      msgs = ChatMessage.where(chat_room_id: rooms.select(:id))
                        .order(created_at: :desc).limit(15).includes(:user)
      return nil if msgs.empty?

      lines = msgs.reverse.map { |m| "- #{m.user&.display_name}: #{m.body.to_s.truncate(120)}" }
      "Recent team messages:\n#{lines.join("\n")}"
    end

    def code_section
      prs = @project.pull_requests.where.not(code_changed: [ nil, "" ]).order(updated_at: :desc).limit(3)
      return nil if prs.empty?

      blocks = prs.map do |pr|
        "PR ##{pr.pr_number} #{pr.title}:\n```diff\n#{pr.code_changed.to_s.truncate(1500)}\n```"
      end
      "Recent code changes:\n#{blocks.join("\n\n")}"
    end
  end
end
