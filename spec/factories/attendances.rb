FactoryBot.define do
  factory :attendance do
    user { nil }
    event { nil }
    status { 1 }
    checked_in_at { "2025-03-21 03:36:02" }
    cancelled_at { "2025-03-21 03:36:02" }
    additional_info { "MyText" }
    form_responses { "" }
  end
end
