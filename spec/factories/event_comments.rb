FactoryBot.define do
  factory :event_comment do
    event { nil }
    user { nil }
    parent_comment { nil }
    content { "MyText" }
    is_hidden { false }
    likes_count { 1 }
  end
end
