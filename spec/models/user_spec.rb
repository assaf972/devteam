require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
  end

  describe 'associations' do
    it { should have_many(:assigned_tickets) }
    it { should have_many(:organized_meetings) }
    it { should have_many(:notifications) }
  end

  describe '#display_name' do
    it 'returns name when present' do
      user = build(:user, name: 'Alice Smith')
      expect(user.display_name).to eq('Alice Smith')
    end
  end

  describe 'enums' do
    it { should define_enum_for(:role).with_values(developer: 0, team_lead: 1, project_manager: 2, admin: 3, qa: 4) }
  end
end
