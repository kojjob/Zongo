FactoryBot.define do
  factory :event_ticket do
    user { nil }
    event { nil }
    ticket_type { nil }
    attendance { nil }
    ticket_code { "MyString" }
    status { 1 }
    amount { "9.99" }
    used_at { "2025-03-21 03:37:40" }
    refunded_at { "2025-03-21 03:37:40" }
    payment_reference { "MyString" }
    transaction_id { "MyString" }
  end
end
