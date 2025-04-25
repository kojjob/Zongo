FactoryBot.define do
  factory :transaction do
    sequence(:transaction_id) { |n| "TXN#{Time.current.to_i}#{n}" }
    amount { 100.0 }
    fee { 1.0 }
    currency { "GHS" }
    status { :pending }
    initiated_at { Time.current }
    
    trait :deposit do
      transaction_type { :deposit }
      association :destination_wallet, factory: :wallet
      payment_method { :mobile_money }
      provider { "MTN" }
    end
    
    trait :withdrawal do
      transaction_type { :withdrawal }
      association :source_wallet, factory: :wallet
      payment_method { :mobile_money }
      provider { "MTN" }
    end
    
    trait :transfer do
      transaction_type { :transfer }
      association :source_wallet, factory: :wallet
      association :destination_wallet, factory: :wallet
      payment_method { :wallet }
    end
    
    trait :payment do
      transaction_type { :payment }
      association :source_wallet, factory: :wallet
      association :destination_wallet, factory: :wallet
      payment_method { :wallet }
    end
    
    trait :completed do
      status { :completed }
      completed_at { Time.current }
    end
    
    trait :failed do
      status { :failed }
      failed_at { Time.current }
    end
    
    trait :reversed do
      status { :reversed }
      reversed_at { Time.current }
    end
    
    trait :blocked do
      status { :blocked }
    end
  end
end
