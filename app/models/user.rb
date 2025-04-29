class User < ApplicationRecord
  # Include Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Active Storage attachment
  has_one_attached :avatar

  # Validations
  validates :username, uniqueness: { case_sensitive: false, allow_blank: true },
                      format: { with: /\A[a-zA-Z0-9_.]+\z/, message: "only allows letters, numbers, dots and underscores", allow_blank: true },
                      length: { minimum: 3, maximum: 30, allow_blank: true }
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :phone, uniqueness: { allow_blank: true, allow_nil: true }
  validates :phone_number, uniqueness: { allow_blank: true, allow_nil: true }
  validates :website, format: { with: URI.regexp(%w[http https]), message: "must be a valid URL", allow_blank: true }

  # Associations
  has_one :wallet, dependent: :destroy
  has_one :user_settings, dependent: :destroy
  has_one :notification_preference, dependent: :destroy
  has_one :cart, dependent: :destroy

  # Notification associations
  has_many :notifications, dependent: :destroy
  has_many :notification_channels, dependent: :destroy

  # Alias for user_settings to handle legacy code
  def setting
    user_settings
  end

  has_many :payment_methods, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :organized_events, class_name: "Event", foreign_key: "organizer_id", dependent: :nullify
  has_many :attendances, dependent: :destroy
  has_many :attending_events, through: :attendances, source: :event
  has_many :comments, dependent: :nullify
  has_many :event_comments, dependent: :nullify
  has_many :beneficiaries, dependent: :destroy
  has_many :bill_payments, dependent: :destroy

  # Transportation associations
  has_many :recent_locations, dependent: :destroy
  has_many :ride_bookings, dependent: :destroy
  has_many :ticket_bookings, dependent: :destroy

  # Education associations
  has_many :school_fee_payments, dependent: :destroy

  # Community associations
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships
  has_many :gathering_attendances, dependent: :destroy
  has_many :gatherings, through: :gathering_attendances
  has_many :organized_gatherings, class_name: "Gathering", foreign_key: "organizer_id", dependent: :nullify

  # Define scheduled_transactions association conditionally
  if ScheduledTransaction.table_exists? && ScheduledTransaction.column_names.include?("user_id")
    has_many :scheduled_transactions, dependent: :destroy
  end

  # Define a method to get scheduled transactions through the wallet if the direct association doesn't exist
  def scheduled_transactions
    if ScheduledTransaction.table_exists? && ScheduledTransaction.column_names.include?("user_id")
      ScheduledTransaction.where(user_id: id)
    else
      wallet ? ScheduledTransaction.where(source_wallet_id: wallet.id) : ScheduledTransaction.none
    end
  end

  has_many :favorites, dependent: :destroy
  has_many :security_logs, dependent: :destroy

  # Add loans and credit_scores associations if the tables exist
  has_many :loans, dependent: :restrict_with_error if ActiveRecord::Base.connection.table_exists?(:loans)
  has_many :loan_refinancings, dependent: :destroy if ActiveRecord::Base.connection.table_exists?(:loan_refinancings)
  has_many :credit_scores, dependent: :destroy if ActiveRecord::Base.connection.table_exists?(:credit_scores)
  has_many :credit_improvement_plans, dependent: :destroy if ActiveRecord::Base.connection.table_exists?(:credit_improvement_plans)

  # Callbacks
  before_save :normalize_phone_fields

  # Enums
  enum :status, { active: 0, suspended: 1, locked: 2, closed: 3 }, default: :active
  enum :kyc_level, { basic: 0, verified: 1, advanced: 2, business: 3 }, default: :basic

  # Convert empty strings to nil for phone fields to avoid uniqueness constraint issues
  def normalize_phone_fields
    self.phone = nil if phone.blank?
    self.phone_number = nil if phone_number.blank?
  end

  # Using Devise's default session serialization

  # PIN management methods
  # Set a new PIN for the user
  # @param pin [String] The new PIN to set
  # @return [Boolean] True if the PIN was set successfully
  def set_pin(pin)
    return false unless pin.present? && pin.length >= 4 && pin.length <= 6 && pin =~ /^\d+$/

    # Use BCrypt to hash the PIN
    require "bcrypt"
    self.pin_digest = BCrypt::Password.create(pin)
    save
  end

  # Authenticate with a PIN
  # @param pin [String] The PIN to check
  # @return [Boolean] True if the PIN is correct
  def authenticate_pin(pin)
    return false unless pin_digest.present?

    require "bcrypt"
    bcrypt_pin = BCrypt::Password.new(pin_digest)
    bcrypt_pin == pin
  end

  # Security related methods

  # Check if account has suspicious activity
  # @return [Boolean] True if suspicious activity has been detected
  def has_suspicious_activity?
    SecurityLog.recent_suspicious_activity?(id)
  end

  # Check if account requires additional verification for transactions
  # @param amount [Decimal] Transaction amount
  # @return [Boolean] True if additional verification is required
  # Check if user profile is complete
  # @return [Boolean] True if all required profile fields are present
  def profile_complete?
    # Check essential attributes
    return false if first_name.blank? || last_name.blank?
    return false if email.blank?
    return false if phone_number.blank?
    return false if kyc_level == "basic"

    # All checks passed
    true
  end

  def requires_additional_verification?(amount = nil)
    # Always require for large transactions if amount is provided
    return true if amount && wallet && amount > wallet.daily_limit * 0.5

    # Require if there's been suspicious activity
    return true if has_suspicious_activity?

    # Require if there have been multiple failed login attempts
    return true if SecurityLog.multiple_failed_logins?(id)

    # Otherwise, no additional verification required
    false
  end

  # Record device identification
  # @param ip_address [String] IP address of the request
  # @param user_agent [String] User agent string
  # @return [Boolean] True if this is a new device, false if known device
  def record_device(ip_address, user_agent)
    # Check if this device has been seen before
    known_device = security_logs.where(ip_address: ip_address, user_agent: user_agent)
                             .where("created_at > ?", 90.days.ago)
                             .exists?

    unless known_device
      # Log new device
      SecurityLog.log_event(
        self,
        :device_change,
        severity: :info,
        details: {
          ip_address: ip_address,
          user_agent: user_agent
        },
        ip_address: ip_address,
        user_agent: user_agent
      )

      return true # New device
    end

    false # Known device
  end

  # Notifications methods

  # Get count of unread notifications
  # @return [Integer] Number of unread notifications
  def unread_notifications_count
    notifications.unread.count
  end

  # Get unread notifications
  # @param limit [Integer] Maximum number of notifications to return
  # @return [ActiveRecord::Relation] Collection of unread notifications
  def unread_notifications(limit = nil)
    scope = notifications.unread.recent_first
    limit ? scope.limit(limit) : scope
  end

  # Get recent notifications
  # @param limit [Integer] Maximum number of notifications to return
  # @return [ActiveRecord::Relation] Collection of recent notifications
  def recent_notifications(limit = 10)
    notifications.recent_first.limit(limit)
  end

  # Mark all notifications as read
  # @return [Integer] Number of notifications marked as read
  def mark_all_notifications_as_read!
    notifications.unread.update_all(read: true, read_at: Time.current)
  end

  # Create a notification for this user
  # @param attributes [Hash] Notification attributes
  # @return [Notification] The created notification
  def create_notification(attributes = {})
    notification = notifications.create!(attributes)
    notification.broadcast_to_user if attributes[:broadcast] != false
    notification
  end

  # Get notification channels of a specific type
  # @param type [String] Channel type (email, sms, push)
  # @return [ActiveRecord::Relation] Collection of notification channels
  def notification_channels_by_type(type)
    notification_channels.where(channel_type: type)
  end

  # Get primary notification channel of a specific type
  # @param type [String] Channel type (email, sms, push)
  # @return [NotificationChannel, nil] Primary notification channel or nil
  def primary_notification_channel(type)
    notification_channels_by_type(type).first
  end

  # Event-related methods
  def attending?(event)
    attending_events.include?(event)
  end

  def favorited?(favoritable)
    return false unless favoritable

    # Handle the case where favorites table might not exist yet
    begin
      favorites.exists?(favoritable: favoritable)
    rescue ActiveRecord::StatementInvalid => e
      if e.message.include?('relation "favorites" does not exist')
        # Check if we can find an event_favorite record instead
        return EventFavorite.exists?(user_id: id, event_id: favoritable.id) if favoritable.is_a?(Event) && defined?(EventFavorite)
        false
      else
        raise e
      end
    end
  end

  def has_favorite_events?
    begin
      favorites.where(favoritable_type: "Event").exists?
    rescue ActiveRecord::StatementInvalid => e
      if e.message.include?('relation "favorites" does not exist')
        # Check if we can find event_favorite records instead
        return EventFavorite.exists?(user_id: id) if defined?(EventFavorite)
        false
      else
        raise e
      end
    end
  end

  def favorite_events
    begin
      Event.joins(:favorites).where(favorites: { user_id: id, favoritable_type: "Event" })
    rescue ActiveRecord::StatementInvalid => e
      if e.message.include?('relation "favorites" does not exist')
        # Fallback to using event_favorites
        return Event.joins(:event_favorites).where(event_favorites: { user_id: id }) if defined?(EventFavorite) && Event.respond_to?(:joins) && Event.method(:joins).arity != 0
        Event.none
      else
        raise e
      end
    end
  end

  def attend_event!(event)
    attendances.create!(event: event)
  end

  def cancel_attendance!(event)
    attendances.find_by(event: event)&.destroy
  end

  def toggle_favorite!(favoritable)
    return false unless favoritable

    # Handle the case where favorites table might not exist yet
    begin
      favorite = favorites.find_by(favoritable: favoritable)

      if favorite
        favorite.destroy
        false
      else
        favorites.create!(favoritable: favoritable)
        true
      end
    rescue ActiveRecord::StatementInvalid => e
      if e.message.include?('relation "favorites" does not exist')
        # If it's an event, use event_favorites as a fallback
        if favoritable.is_a?(Event) && defined?(EventFavorite)
          event_favorite = EventFavorite.find_by(user_id: id, event_id: favoritable.id)
          if event_favorite
            event_favorite.destroy
            false
          else
            EventFavorite.create!(user_id: id, event_id: favoritable.id)
            true
          end
        else
          false # Can't toggle favorites for other types if table doesn't exist
        end
      else
        raise e
      end
    end
  end

  # Profile image placeholder method - customize based on your implementation
  def profile_image
    # This is a placeholder method
    OpenStruct.new(url: "/assets/images/default-avatar.jpg")
  end

  def full_name
    # Use username, email, or a default when name isn't available
    username.presence || email.split("@").first || "Anonymous User"
  end

  def first_name
    # Use the first part of the full name or username
    full_name.split(" ").first
  end

  def last_name
    # Use the last part of the full name or blank if not available
    parts = full_name.split(" ")
    parts.length > 1 ? parts.last : ""
  end

  def initials
    first = first_name.to_s[0] || ""
    last = last_name.to_s[0] || ""

    if first.present? || last.present?
      "#{first}#{last}".upcase
    else
      "U"
    end
  end

  # Role-related methods

  # Check if user is an admin
  def admin?
    respond_to?(:admin) && admin == true
  end

  # For now, super_admin is the same as admin
  # This can be updated later when the super_admin field is added
  def super_admin?
    admin?
  end

  # Check if user is a seller/trader
  def seller?
    respond_to?(:seller) && seller == true
  end

  # Alias for seller
  def trader?
    seller?
  end

  # Check if user has admin privileges
  def has_admin_privileges?
    admin?
  end

  # Check if user has a specific role
  # This is a compatibility method for role-based authorization systems
  def has_role?(role_name)
    return true if role_name.to_sym == :admin && admin?
    return true if role_name.to_sym == :super_admin && super_admin?
    return true if role_name.to_sym == :seller && seller?
    return true if role_name.to_sym == :trader && seller?
    false
  end

  # Check if user can manage the specified resource
  def can_manage?(resource)
    return true if admin?
    false
  end

  # User display name to show in the UI
  def display_name
    # Use username if available, otherwise use email or full name
    username.presence || full_name.presence || email
  end

  # Get recent transfer recipients for this user
  # @param limit [Integer] Maximum number of recipients to return
  # @return [Array<User>] Array of recent recipients
  def recent_transfer_recipients(limit = 5)
    # Find recent outgoing transfers from this user's wallet
    return [] unless wallet.present?

    # Get recent successful transfers
    recent_transfers = Transaction.where(source_wallet_id: wallet.id, transaction_type: :transfer, status: :completed)
                                 .order(created_at: :desc)
                                 .limit(limit * 2) # Fetch more to account for duplicates

    # Extract unique recipient users
    recipient_ids = recent_transfers.map(&:destination_wallet).compact.map(&:user_id).uniq

    # Return the users in the same order as the transfers
    recipients = User.where(id: recipient_ids).index_by(&:id)
    recipient_ids.map { |id| recipients[id] }.compact.take(limit)
  end

  # Loan-related methods

  # Get the user's current credit score
  # @return [CreditScore, nil] The current credit score or nil if none exists
  def current_credit_score
    begin
      if CreditScore.column_names.include?("is_current")
        credit_scores.current.first
      else
        # Fallback if is_current column doesn't exist
        credit_scores.order(created_at: :desc).first
      end
    rescue => e
      Rails.logger.error("Error getting credit score: #{e.message}")
      nil
    end
  end

  # Check if the user is eligible for a loan
  # @return [Boolean] True if eligible for a loan
  def eligible_for_loan?
    # Basic eligibility logic
    has_verified_identity? &&
    current_credit_score.present? &&
    current_credit_score.score >= 500 &&
    !has_active_defaulted_loan?
  end

  # Check if the user has verified their identity
  # @return [Boolean] True if identity is verified
  def has_verified_identity?
    # Consider a user verified if they have completed KYC
    kyc_level != "basic"
  end

  # Check if the user has an active or defaulted loan
  # @return [Boolean] True if there's an active or defaulted loan
  def has_active_defaulted_loan?
    loans.where(status: [ :active, :defaulted ]).exists?
  end

  # Calculate the maximum loan amount the user is eligible for
  # @return [Decimal] The maximum loan amount
  def loan_limit
    return 0 unless eligible_for_loan?

    # Calculate loan limit based on credit score and other factors
    base_limit = 500 # Base amount in GHS

    if current_credit_score.score >= 700
      base_limit * 5
    elsif current_credit_score.score >= 600
      base_limit * 3
    elsif current_credit_score.score >= 500
      base_limit
    else
      0
    end
  end

  # Get the user's primary wallet
  # @return [Wallet] The user's primary wallet
  def primary_wallet
    wallet
  end

  # Credit improvement plan methods

  # Get the user's current active credit improvement plan
  # @return [CreditImprovementPlan, nil] The current active plan or nil if none exists
  def current_credit_improvement_plan
    return nil unless ActiveRecord::Base.connection.table_exists?(:credit_improvement_plans)
    credit_improvement_plans.current.first
  end

  # Check if the user has an active credit improvement plan
  # @return [Boolean] True if an active plan exists
  def has_active_credit_improvement_plan?
    current_credit_improvement_plan.present?
  end

  # Get or create a credit improvement plan for the user
  # @return [CreditImprovementPlan] The current or newly created plan
  def get_or_create_credit_improvement_plan
    return current_credit_improvement_plan if has_active_credit_improvement_plan?

    # Create a new plan
    CreditImprovementPlan.generate_for(self)
  end

  # Get the user's credit improvement progress
  # @return [Hash] Hash containing progress information
  def credit_improvement_progress
    plan = current_credit_improvement_plan
    return {} unless plan.present?

    {
      progress_percentage: plan.progress_percentage,
      starting_score: plan.starting_score,
      current_score: current_credit_score&.score || plan.starting_score,
      target_score: plan.target_score,
      on_track: plan.on_track?,
      completed_steps: plan.credit_improvement_steps.completed.count,
      total_steps: plan.credit_improvement_steps.count
    }
  end

  # Get all transactions for this user (both sent and received)
  # @return [ActiveRecord::Relation] Collection of transactions
  def transactions
    return Transaction.none unless wallet.present?

    # Get transactions where this user's wallet is either the source or destination
    Transaction.where("source_wallet_id = ? OR destination_wallet_id = ?", wallet.id, wallet.id)
              .order(created_at: :desc)
  end
end
