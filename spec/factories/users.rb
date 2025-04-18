FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:phone) { |n| "0#{n}00000000" }  # Add unique phone number
    password { "password123" }
    password_confirmation { "password123" }
    status { :active }
    kyc_level { :basic }

    trait :with_wallet do
      after(:create) do |user|
        create(:wallet, user: user)
      end
    end

    trait :admin do
      admin { true }
    end
  end
end
