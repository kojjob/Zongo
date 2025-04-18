module ML
  class FraudDetectionService
    # Minimum number of transactions required for pattern-based detection
    MIN_TRANSACTIONS_FOR_PATTERN = 5

    # Risk thresholds
    LOW_RISK_THRESHOLD = 30
    MEDIUM_RISK_THRESHOLD = 60
    HIGH_RISK_THRESHOLD = 80

    # Initialize the service with default parameters
    # @param model_version [String] Version of the ML model to use
    # @param sensitivity [Symbol] Detection sensitivity (:low, :medium, :high)
    def initialize(model_version: "v1", sensitivity: :medium)
      @model_version = model_version
      @sensitivity = sensitivity
      @threshold_modifier = sensitivity_to_modifier(sensitivity)
      @cache_enabled = true

      # Initialize ML model connection
      initialize_model if load_model?
    end

    # Analyze transaction for fraud indicators
    # @param transaction [Transaction] The transaction to analyze
    # @param user [User] The user performing the transaction
    # @param context [Hash] Additional context for analysis
    # @return [Hash] Analysis results including risk score and reasons
    def analyze_transaction(transaction, user, context = {})
      # Basic validation
      return { error: "Invalid transaction" } unless transaction&.valid?
      return { error: "Invalid user" } unless user&.valid?

      # Check if we have enough transaction history for this user
      has_history = has_sufficient_history?(user)

      # Extract features for analysis
      features = extract_transaction_features(transaction, user, context)

      # Calculate risk score
      risk_score = calculate_risk_score(features, has_history)

      # Determine risk level
      risk_level = determine_risk_level(risk_score)

      # Generate explanation
      reasons = generate_risk_explanations(features, risk_score, risk_level)

      # Build result
      {
        transaction_id: transaction.id,
        user_id: user.id,
        risk_score: risk_score,
        risk_level: risk_level,
        reasons: reasons,
        features: features.except(:user_history), # Exclude large history data from response
        analyzed_at: Time.current,
        model_version: @model_version,
        sensitivity: @sensitivity
      }
    end

    # Analyze a batch of transactions for fraud patterns
    # @param transactions [Array<Transaction>] Array of transactions to analyze
    # @return [Hash] Analysis results for each transaction
    def analyze_batch(transactions)
      results = {}

      # Group transactions by user for more efficient processing
      transactions_by_user = transactions.group_by { |t| t.source_wallet&.user_id || t.destination_wallet&.user_id }

      transactions_by_user.each do |user_id, user_transactions|
        user = User.find_by(id: user_id)
        next unless user

        # Extract user history once for all transactions
        user_history = extract_user_history(user)

        # Analyze each transaction
        user_transactions.each do |transaction|
          context = { user_history: user_history }
          results[transaction.id] = analyze_transaction(transaction, user, context)
        end
      end

      results
    end

    # Detect unusual patterns in user behavior
    # @param user [User] The user to analyze
    # @param timeframe [Integer] Number of days of history to analyze
    # @return [Hash] Analysis results of user behavior patterns
    def detect_unusual_patterns(user, timeframe = 30)
      # Get user transaction history
      history = get_user_transaction_history(user, timeframe)

      return { error: "Insufficient transaction history" } if history.size < MIN_TRANSACTIONS_FOR_PATTERN

      # Analyze transaction patterns
      patterns = analyze_transaction_patterns(history)

      # Detect anomalies in patterns
      anomalies = detect_anomalies(patterns, user)

      # Calculate overall anomaly score
      anomaly_score = calculate_anomaly_score(anomalies)

      {
        user_id: user.id,
        anomaly_score: anomaly_score,
        anomalies: anomalies,
        analyzed_at: Time.current,
        model_version: @model_version
      }
    end

    private

    # Initialize ML model connection
    def initialize_model
      # In a real implementation, this would load a trained ML model
      # For example, using TensorFlow, PyTorch, or a custom Ruby ML library
      #
      # Example:
      # @model = TensorFlowService.load_model("fraud_detection_#{@model_version}")

      # For this implementation, we'll just log the initialization
      Rails.logger.info("Initializing fraud detection model version #{@model_version}")
    end

    # Check if model should be loaded
    # In production, you might want to check environment configs
    def load_model?
      Rails.env.production? || Rails.env.staging?
    end

    # Convert sensitivity level to a threshold modifier
    # @param sensitivity [Symbol] The sensitivity level
    # @return [Float] The threshold modifier
    def sensitivity_to_modifier(sensitivity)
      case sensitivity
      when :low then 1.2     # Higher threshold (less sensitive)
      when :high then 0.8    # Lower threshold (more sensitive)
      else 1.0               # Medium (default) sensitivity
      end
    end

    # Check if user has sufficient transaction history for pattern analysis
    # @param user [User] The user to check
    # @return [Boolean] True if sufficient history exists
    def has_sufficient_history?(user)
      return false unless user&.wallet

      # Count user's transactions
      transaction_count = Transaction.where("source_wallet_id = ? OR destination_wallet_id = ?",
                                          user.wallet.id, user.wallet.id)
                                    .count

      transaction_count >= MIN_TRANSACTIONS_FOR_PATTERN
    end

    # Extract features from a transaction for ML analysis
    # @param transaction [Transaction] The transaction to analyze
    # @param user [User] The user associated with the transaction
    # @param context [Hash] Additional context
    # @return [Hash] Features for ML analysis
    def extract_transaction_features(transaction, user, context = {})
      # Basic transaction features
      features = {
        amount: transaction.amount,
        transaction_type: transaction.transaction_type,
        payment_method: transaction.payment_method,
        currency: transaction.currency,
        time_of_day: transaction.created_at.hour,
        day_of_week: transaction.created_at.wday,
        weekend: [ 0, 6 ].include?(transaction.created_at.wday)
      }

      # Add user account features
      features.merge!(
        account_age_days: ((Time.current - user.created_at) / 1.day).to_i,
        kyc_level: user.respond_to?(:kyc_level) ? user.kyc_level : 0,
        is_verified: user.respond_to?(:verified) ? user.verified : false,
        login_count: user.respond_to?(:sign_in_count) ? user.sign_in_count : 0
      )

      # Add location/device features if available
      if transaction.ip_address.present?
        features[:ip_address] = transaction.ip_address
        features[:location] = extract_location_features(transaction.ip_address)
        features[:is_new_ip] = is_new_ip?(user, transaction.ip_address)
      end

      if transaction.user_agent.present?
        features[:device_type] = extract_device_type(transaction.user_agent)
        features[:is_new_device] = is_new_device?(user, transaction.user_agent)
      end

      # Add history-based features
      features[:user_history] = context[:user_history] || extract_user_history(user)

      # Derive velocity features
      features.merge!(calculate_velocity_features(features[:user_history]))

      # Add recipient relationship features for transfers
      if transaction.transaction_type == "transfer" && transaction.destination_wallet
        features[:recipient_relationship] = analyze_recipient_relationship(
          user,
          transaction.destination_wallet.user
        )
      end

      features
    end

    # Calculate median of a numeric array
    # @param array [Array<Numeric>] The array to calculate median for
    # @return [Numeric] The median value
    def median(array)
      return nil if array.empty?

      sorted = array.sort
      mid = sorted.length / 2

      if sorted.length.odd?
        sorted[mid]
      else
        (sorted[mid-1] + sorted[mid]) / 2.0
      end
    end
  end
end
