FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Category #{n}" }
    description { "MyText" }
    icon { "MyString" }
    color_code { "#FF5733" }
    display_order { 0 }
  end
end
