class TransactionSecurityService
  attr_reader :transaction, :user, :ip_address, :user_agent, :errors

  # Initialize with transaction, user, and request data
  # @param transaction [Transaction] The transaction being evaluated
  # @param user [User] The user performing the transaction
  # @param ip_address [String] The IP address of the user's request
  # @param user_agent [String] The user agent string from the request
  def initialize(transaction, user, ip_address = nil, user_agent = nil)
    @transaction = transaction
    @user = user
    @ip_address = ip_address
    @user_agent = user_agent
    @errors = []
  end

  # Verify if a transaction is secure and should be allowed
  # @return [Boolean] True if the transaction passes all security checks
  def secure?
    # Only run checks if there's a transaction to check
    return false unless transaction.present?

    # Run each security check
    check_velocity_limits &&
      check_unusual_location &&
      check_device_fingerprint &&
      check_high_risk_patterns &&
      check_amount_threshold
  end

  # Check if transaction exceeds velocity limits
  # @return [Boolean] True if within limits
  def check_velocity_limits
    # Get source wallet for transaction
    wallet = transaction.source_wallet

    # Skip if no source wallet (like deposits)
    return true unless wallet

    # Calculate total outgoing amount in the last 24 hours
    daily_total = wallet.sent_transactions
                       .where(status: [ :pending, :completed ])
                       .where("created_at > ?", 24.hours.ago)
                       .sum(:amount)

    # Include current transaction amount in the calculation
    daily_total += transaction.amount

    # Check if this exceeds the daily limit
    if daily_total > wallet.daily_limit
      @errors << "Transaction would exceed your daily limit of #{wallet.currency_symbol}#{wallet.daily_limit}"
      return false
    end

    # Weekly limit check (default to 7x daily limit if not set)
    weekly_limit = wallet.respond_to?(:weekly_limit) ? wallet.weekly_limit : wallet.daily_limit * 7
    weekly_total = wallet.sent_transactions
                        .where(status: [ :pending, :completed ])
                        .where("created_at > ?", 7.days.ago)
                        .sum(:amount)
    weekly_total += transaction.amount

    if weekly_total > weekly_limit
      @errors << "Transaction would exceed your weekly limit"
      return false
    end

    true
  end

  # Check if the transaction is coming from an unusual location
  # @return [Boolean] True if the location appears normal
  def check_unusual_location
    return true if ip_address.blank? # Skip if no IP provided

    # Get recent IP addresses used by this user
    recent_ips = Transaction.where("source_wallet_id IN (?) OR destination_wallet_id IN (?)",
                                 user.wallet.id, user.wallet.id)
                          .where("created_at > ?", 30.days.ago)
                          .where.not(ip_address: nil)
                          .distinct
                          .pluck(:ip_address)

    # If this is first transaction or IP is among recent ones, it's probably fine
    return true if recent_ips.empty? || recent_ips.include?(ip_address)

    # Track this as a new IP address but allow it for now
    # In a real system, you might want to trigger additional verification
    # if the geolocation of the IP is significantly different

    # Log the new IP address for review
    Rails.logger.info("User #{user.id} using new IP address: #{ip_address} for transaction #{transaction.id}")

    # For a robust implementation, use a geolocation service to check if the location is suspicious
    # This is commented out as it would require external API integration
    #
    # if GeoLocationService.suspicious_location?(ip_address, user.id)
    #   @errors << "Transaction from unusual location detected"
    #   return false
    # end

    true
  end

  # Check device fingerprint for suspicious signals
  # @return [Boolean] True if the device fingerprint is acceptable
  def check_device_fingerprint
    return true if user_agent.blank? # Skip if no user agent provided

    # Get recent user agents used by this user
    recent_user_agents = Transaction.where("source_wallet_id IN (?) OR destination_wallet_id IN (?)",
                                         user.wallet.id, user.wallet.id)
                                  .where("created_at > ?", 30.days.ago)
                                  .where.not(user_agent: nil)
                                  .distinct
                                  .pluck(:user_agent)

    # If this is first transaction or user agent is among recent ones, it's likely fine
    return true if recent_user_agents.empty? || recent_user_agents.include?(user_agent)

    # Check for suspicious user agent patterns
    suspicious_patterns = [
      /bot/i,
      /crawler/i,
      /spider/i,
      /headless/i,
      /automation/i
    ]

    if suspicious_patterns.any? { |pattern| user_agent =~ pattern }
      @errors << "Suspicious device detected"
      return false
    end

    # Track new user agent but allow it
    Rails.logger.info("User #{user.id} using new user agent: #{user_agent} for transaction #{transaction.id}")

    true
  end

  # Check for high-risk transaction patterns
  # @return [Boolean] True if no high-risk patterns are found
  def check_high_risk_patterns
    # Skip for deposits as they're less risky
    return true if transaction.transaction_type == "deposit"

    # Check for immediate withdrawal after recent large deposit
    if transaction.transaction_type == "withdrawal"
      recent_large_deposits = Transaction.where(destination_wallet_id: user.wallet.id,
                                              transaction_type: "deposit",
                                              status: "completed")
                                       .where("created_at > ?", 24.hours.ago)
                                       .where("amount > ?", transaction.amount * 0.8) # 80% or more of withdrawal amount
                                       .exists?

      if recent_large_deposits
        # This is suspicious but we allow it with a warning flag
        Rails.logger.warn("User #{user.id} withdrawing soon after large deposit: #{transaction.id}")
        # In a production system, you might want to flag this for manual review
      end
    end

    # Check for multiple small transactions that sum to just under limit
    # (Structuring/Smurfing detection)
    if transaction.amount > 0 && transaction.amount < user.wallet.daily_limit * 0.2 # Less than 20% of daily limit
      small_transactions_count = Transaction.where(source_wallet_id: user.wallet.id)
                                          .where("created_at > ?", 24.hours.ago)
                                          .where("amount BETWEEN ? AND ?",
                                                transaction.amount * 0.5,
                                                transaction.amount * 1.5)
                                          .count

      if small_transactions_count >= 5 # Multiple similar small transactions
        @errors << "Multiple similar transactions detected. Please try again later or contact support."
        return false
      end
    end

    # Check for unusual transaction timing
    user_local_time = Time.current
    if user.respond_to?(:time_zone) && user.time_zone.present?
      # Convert to user's local time if available
      user_local_time = Time.current.in_time_zone(user.time_zone)
    end

    # Check if transaction is happening during unusual hours (2 AM - 5 AM local time)
    if user_local_time.hour >= 2 && user_local_time.hour <= 5
      # Log unusually timed transaction but allow it
      Rails.logger.info("User #{user.id} transaction at unusual hour: #{user_local_time.hour}:#{user_local_time.min}")

      # For higher amounts, we might want to add additional verification
      if transaction.amount > user.wallet.daily_limit * 0.5 # 50% of daily limit
        # This would be a place to trigger enhanced verification
        Rails.logger.warn("Large transaction at unusual hour requires additional verification: #{transaction.id}")
      end
    end

    true
  end

  # Check if the transaction exceeds amount thresholds that need additional verification
  # @return [Boolean] True if the amount doesn't need additional verification or verification is provided
  def check_amount_threshold
    # Skip for deposits as they're typically verified by the payment provider
    return true if transaction.transaction_type == "deposit"

    # Define verification thresholds based on user's verified status and account age
    user_kyc_level = user.respond_to?(:kyc_level) ? user.kyc_level : 0
    account_age_days = ((Time.current - user.created_at) / 1.day).to_i

    # Determine the threshold based on KYC level and account age
    # Higher KYC level and older accounts get higher thresholds
    verification_threshold = case user_kyc_level
    when 0
                               50.0 # Lowest verification level
    when 1
                               account_age_days < 30 ? 200.0 : 500.0
    when 2
                               account_age_days < 30 ? 1000.0 : 2000.0
    else
                               5000.0 # Highest verification level
    end

    # If transaction is below threshold, no additional verification needed
    return true if transaction.amount <= verification_threshold

    # Otherwise check if verification (like PIN entry) was provided
    if transaction.metadata.present? && transaction.metadata["verification_provided"] == true
      return true
    end

    # If we get here, the transaction needs additional verification
    @errors << "Transaction amount requires additional verification"
    false
  end

  # Calculate risk score for the transaction
  # @return [Integer] Risk score (0-100, higher means more risky)
  def calculate_risk_score
    score = 0

    # Add points based on transaction type
    score += case transaction.transaction_type
    when "withdrawal" then 30
    when "transfer" then 20
    when "payment" then 15
    when "deposit" then 5
    end

    # Add points for amount (as percentage of daily limit)
    wallet = transaction.transaction_type == "deposit" ? transaction.destination_wallet : transaction.source_wallet
    if wallet
      amount_percent = (transaction.amount / wallet.daily_limit) * 100
      score += [ amount_percent.to_i, 40 ].min # Cap at 40 points
    end

    # Add points for velocity
    if wallet
      daily_transactions = wallet.sent_transactions.where("created_at > ?", 24.hours.ago).count
      score += [ daily_transactions * 2, 15 ].min # Cap at 15 points
    end

    # Subtract points for account age/reputation
    account_age_months = ((Time.current - user.created_at) / 1.month).to_i
    score -= [ account_age_months, 20 ].min # Cap at 20 points

    # Ensure score is between 0-100
    [ 0, [ score, 100 ].min ].max
  end

  # Log security check for auditing purposes
  # @param result [Boolean] Whether the transaction passed security checks
  def log_security_check(result)
    # Create a security log entry
    log_data = {
      user_id: user.id,
      transaction_id: transaction.id,
      transaction_type: transaction.transaction_type,
      amount: transaction.amount,
      currency: transaction.currency,
      ip_address: ip_address,
      user_agent: user_agent,
      risk_score: calculate_risk_score,
      result: result,
      errors: errors,
      created_at: Time.current
    }

    # In a real implementation, this would be saved to a database table
    Rails.logger.info("TRANSACTION SECURITY LOG: #{log_data.to_json}")

    # Return the log data for possible further processing
    log_data
  end
end
