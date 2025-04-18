FactoryBot.define do
  factory :wallet do
    association :user
    sequence(:wallet_id) { |n| "WALLET#{n}#{Time.current.to_i}" }
    balance { 1000.0 }
    currency { "GHS" }
    daily_limit { 5000.0 }
    status { :active }

    trait :empty do
      balance { 0.0 }
    end

    trait :high_balance do
      balance { 10000.0 }
    end

    trait :inactive do
      status { :inactive }
    end
  end
end
