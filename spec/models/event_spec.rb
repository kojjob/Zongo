require 'rails_helper'

RSpec.describe Event, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:end_date) }
    it { should validate_presence_of(:user) }

    it 'validates that end_date is after start_date' do
      event = build(:event, start_date: Time.current, end_date: 1.day.ago)
      expect(event).not_to be_valid
      expect(event.errors[:end_date]).to include('must be after start date')
    end
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:venue).optional }
    it { should have_many(:comments).dependent(:destroy) }
    it { should have_many(:favorites).dependent(:destroy) }
    it { should have_many(:ticket_types).dependent(:destroy) }
  end

  describe 'scopes' do
    describe '.upcoming' do
      it 'returns events with start_date in the future' do
        future_event = create(:event, start_date: 1.day.from_now)
        past_event = create(:event, start_date: 1.day.ago)

        expect(Event.upcoming).to include(future_event)
        expect(Event.upcoming).not_to include(past_event)
      end
    end

    describe '.past' do
      it 'returns events with end_date in the past' do
        past_event = create(:event, end_date: 1.day.ago)
        future_event = create(:event, end_date: 1.day.from_now)

        expect(Event.past).to include(past_event)
        expect(Event.past).not_to include(future_event)
      end
    end
  end

  describe '#duration' do
    it 'returns the duration between start_date and end_date' do
      event = build(:event, start_date: Time.current, end_date: 2.days.from_now)
      expect(event.duration).to eq(2.days)
    end
  end

  describe '#favorited_by?' do
    let(:user) { create(:user) }
    let(:event) { create(:event) }

    it 'returns true if user has favorited the event' do
      create(:favorite, user: user, event: event)
      expect(event.favorited_by?(user)).to be true
    end

    it 'returns false if user has not favorited the event' do
      expect(event.favorited_by?(user)).to be false
    end
  end
end
