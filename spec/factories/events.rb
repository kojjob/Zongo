FactoryBot.define do
  factory :event do
    title { "MyString" }
    description { "MyText" }
    short_description { "MyText" }
    start_time { 1.day.from_now }
    end_time { 2.days.from_now }
    capacity { 1 }
    status { 1 }
    is_featured { false }
    is_private { false }
    access_code { "MyString" }
    sequence(:slug) { |n| "my-event-#{n}" }
    association :organizer, factory: :user
    # Corrected association to match the Event model's belongs_to :event_category
    association :event_category, factory: :event_category
    # association :category, factory: :category # This was incorrect
    association :venue # Venue is required
    recurrence_type { 1 }
    recurrence_pattern { "" }
    # parent_event has been removed or renamed
    # parent_event { nil }
    favorites_count { 1 }
    views_count { 1 }
    custom_fields { "" }
  end
end
