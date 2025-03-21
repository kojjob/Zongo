FactoryBot.define do
  factory :venue do
    name { "MyString" }
    description { "MyText" }
    address { "MyString" }
    city { "MyString" }
    region { "MyString" }
    postal_code { "MyString" }
    country { "MyString" }
    latitude { "9.99" }
    longitude { "9.99" }
    capacity { 1 }
    user { nil }
    facilities { "" }
  end
end
