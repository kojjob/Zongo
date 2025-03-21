FactoryBot.define do
  factory :event do
    title { "MyString" }
    description { "MyText" }
    short_description { "MyText" }
    start_time { "2025-03-21 03:30:17" }
    end_time { "2025-03-21 03:30:17" }
    capacity { 1 }
    status { 1 }
    is_featured { false }
    is_private { false }
    access_code { "MyString" }
    slug { "MyString" }
    organizer { nil }
    event_category { nil }
    venue { nil }
    recurrence_type { 1 }
    recurrence_pattern { "" }
    parent_event { nil }
    favorites_count { 1 }
    views_count { 1 }
    custom_fields { "" }
  end
end
