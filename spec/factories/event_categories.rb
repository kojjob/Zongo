FactoryBot.define do
  factory :event_category do
    name { "MyString" }
    description { "MyText" }
    icon { "MyString" }
    parent_category { nil }
  end
end
