class ContactSubmission < ApplicationRecord
  # Validations
  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message, presence: true
  
  # Optional phone validation (Ghana format)
  validates :phone, format: { 
    with: /\A(?:\+233|233|0)(?:(?:24|54|55|59|50|27|57|26|56|23|28|20|50|24)[0-9]{7})\z/, 
    message: "must be a valid Ghana phone number", 
    allow_blank: true 
  }
  
  # Scopes
  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }
  
  # Callbacks
  after_create :send_notification_email
  
  private
  
  def send_notification_email
    # This will be called automatically when a new submission is created
    ContactMailer.new_message(self).deliver_later
  end
end