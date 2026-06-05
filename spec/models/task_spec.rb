require 'rails_helper'

RSpec.describe Task, type: :model do
  let(:project) { create(:project) }
  let(:ticket)  { create(:ticket, project: project) }

  it "requires a description" do
    expect(build(:task, description: nil)).not_to be_valid
  end

  describe "status derived from timestamps" do
    it "is not_started with no timestamps" do
      expect(build(:task).status).to eq("not_started")
    end

    it "is in_progress once started" do
      task = create(:task, ticket: ticket)
      task.start!
      expect(task.status).to eq("in_progress")
    end

    it "is completed once completed" do
      task = create(:task, ticket: ticket)
      task.complete!
      expect(task.status).to eq("completed")
      expect(task.started_at).to be_present # complete also stamps started_at
    end

    it "can be reopened" do
      task = create(:task, ticket: ticket)
      task.complete!
      task.reopen!
      expect(task.completed_at).to be_nil
    end
  end

  describe "Ticket#task_progress" do
    it "is zero when there are no tasks" do
      bug = create(:ticket, project: project, kind: :bug_fix)
      expect(bug.task_progress).to eq(total: 0, completed: 0, percent: 0)
    end

    it "computes completion percentage" do
      bug = create(:ticket, project: project, kind: :bug_fix)
      create(:task, ticket: bug)
      create(:task, ticket: bug).complete!
      expect(bug.reload.task_progress).to eq(total: 2, completed: 1, percent: 50)
    end
  end

  describe "auto-creating the first task for a story" do
    it "creates one task named after the story on create" do
      story = create(:ticket, project: project, kind: :story, title: "As a user I want X")
      expect(story.tasks.count).to eq(1)
      expect(story.tasks.first.description).to eq("As a user I want X")
    end

    it "does not auto-create a task for non-story tickets" do
      bug = create(:ticket, project: project, kind: :bug_fix)
      expect(bug.tasks.count).to eq(0)
    end
  end
end
