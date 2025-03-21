FactoryBot.define do
  factory :user_setting do
    user { nil }
    theme_preference { "MyString" }
    language { "MyString" }
    currency_display { "MyString" }
    email_notifications { false }
    sms_notifications { false }
    push_notifications { false }
    deposit_alerts { false }
    withdrawal_alerts { false }
    transfer_alerts { false }
    low_balance_alerts { false }
    login_alerts { false }
    password_alerts { false }
    product_updates { false }
    promotional_emails { false }
  end
end
