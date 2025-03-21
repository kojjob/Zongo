class UserSetting < ApplicationRecord
  belongs_to :user

  # Enums
  enum :theme_preference, { auto: 0, light: 1, dark: 2 }, default: :auto
  enum :language, { en: 0, fr: 1, es: 2, de: 3, pt: 4 }, default: :en
  enum :currency_display, { ghs: 0, usd: 1, eur: 2, gbp: 3, ngn: 4 }, default: :ghs
  
  # Validations
  validates :user_id, presence: true, uniqueness: true
  
  # Default settings
  after_initialize :set_defaults, if: :new_record?
  
  private
  
  def set_defaults
    self.theme_preference    ||= :auto
    self.language            ||= :en
    self.currency_display    ||= :ghs
    self.email_notifications  = true if email_notifications.nil?
    self.sms_notifications    = false if sms_notifications.nil?
    self.push_notifications   = true if push_notifications.nil?
    self.deposit_alerts       = true if deposit_alerts.nil?
    self.withdrawal_alerts    = true if withdrawal_alerts.nil?
    self.transfer_alerts      = true if transfer_alerts.nil?
    self.low_balance_alerts   = true if low_balance_alerts.nil?
    self.login_alerts         = true if login_alerts.nil?
    self.password_alerts      = true if password_alerts.nil?
    self.product_updates      = false if product_updates.nil?
    self.promotional_emails   = false if promotional_emails.nil?
  end
end