FactoryBot.define do
  factory :event_medium do
    event { nil }
    user { nil }
    media_type { 1 }
    title { "MyString" }
    description { "MyText" }
    is_featured { false }
    display_order { 1 }
  end
end
