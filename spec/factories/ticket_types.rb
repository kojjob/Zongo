FactoryBot.define do
  factory :ticket_type do
    event { nil }
    name { "MyString" }
    description { "MyText" }
    price { "9.99" }
    quantity { 1 }
    sales_start_time { "2025-03-21 03:34:19" }
    sales_end_time { "2025-03-21 03:34:19" }
    sold_count { 1 }
    max_per_user { 1 }
    transferable { false }
  end
end
