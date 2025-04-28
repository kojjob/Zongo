class WalletController < ApplicationController
  require "securerandom"

  before_action :authenticate_user!  # Ensures user is logged in before accessing any wallet actions
  before_action :set_wallet          # Sets @wallet instance variable for all controller actions

  # Dashboard action - displays wallet overview with recent activity
  def dashboard
    # Get recent transactions
    recent_count = Rails.application.config.x.wallet[:dashboard_recent_transactions_count] || 5

    # Get transaction type from params or default to 'all'
    @active_tab = params[:tab] || 'all'

    # Filter transactions based on the active tab
    base_query = @wallet.transactions.order(created_at: :desc)

    @recent_transactions = case @active_tab
    when 'deposits'
      base_query.where(transaction_type: 'deposit').limit(recent_count)
    when 'withdrawals'
      base_query.where(transaction_type: 'withdrawal').limit(recent_count)
    when 'transfers'
      base_query.where(transaction_type: 'transfer').limit(recent_count)
    when 'payments'
      base_query.where(transaction_type: 'payment').limit(recent_count)
    else # 'all'
      base_query.limit(recent_count)
    end

    # Get beneficiaries - handle case where beneficiaries might not exist yet
    # Uses respond_to? to safely check if the association exists before trying to access it
    beneficiaries_count = Rails.application.config.x.wallet[:dashboard_recent_beneficiaries_count] || 5
    @beneficiaries = if current_user.respond_to?(:beneficiaries)
                      current_user.beneficiaries.order(created_at: :desc).limit(beneficiaries_count)
    else
                      []
    end

    # Calculate savings (incoming money) and spending (outgoing money)
    period_days = Rails.application.config.x.wallet[:dashboard_financial_period_days] || 30
    @savings_total = @wallet.total_incoming(start_date: period_days.days.ago, end_date: Date.current)
    @spending_total = @wallet.total_outgoing(start_date: period_days.days.ago, end_date: Date.current)

    # Calculate percentage changes (example calculation - would be based on previous period in real app)
    @savings_change = Rails.application.config.x.wallet[:placeholder_savings_change] || 16.8
    @spending_change = Rails.application.config.x.wallet[:placeholder_spending_change] || -16.8
  end

  # Include Pagy for pagination if available
  # This is a conditional inclusion of the Pagy gem for pagination
  begin
    require "pagy"
    include Pagy::Backend
  rescue LoadError
    # Fallback method if Pagy is not available
    # Custom implementation of pagination functionality when Pagy gem is not installed
    def pagy(collection, options = {})
      items = options[:items] || Rails.application.config.x.wallet[:pagination_items_per_page] || 20
      page = (params[:page] || 1).to_i

      total = collection.count
      offset = (page - 1) * items
      subset = collection.offset(offset).limit(items)

      # Simple OpenStruct to mimic Pagy behavior
      # Creates an object with pagination metadata similar to what Pagy would provide
      pagy_obj = OpenStruct.new(
        count: total,
        page: page,
        items: items,
        pages: (total.to_f / items).ceil,
        prev: page > 1 ? page - 1 : nil,
        next: page * items < total ? page + 1 : nil,
        offset: offset,
        from: offset + 1,
        to: [ offset + items, total ].min,
        total_count: total
      )

      return pagy_obj, subset
    end
  end

  # Transactions action - displays filtered transaction history
  def transactions
    # Set default date range if not provided (last 90 days)
    default_days = Rails.application.config.x.wallet[:default_transaction_history_days] || 90
    start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : default_days.days.ago.to_date
    end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current

    # Use wallet's transaction_history method to get base query
    base_query = @wallet.transaction_history(start_date: start_date, end_date: end_date)

    # Apply transaction type filter if provided (deposit, withdrawal, transfer, payment)
    if params[:transaction_type].present? && params[:transaction_type] != "all"
      base_query = base_query.where(transaction_type: params[:transaction_type])
    end

    # Apply status filter if provided (pending, completed, failed, reversed, blocked)
    if params[:status].present? && params[:status] != "all"
      base_query = base_query.where(status: params[:status])
    end

    # Apply predefined date range filters
    case params[:date_range]
    when "today"
      base_query = base_query.where("created_at >= ?", Date.current.beginning_of_day)
    when "yesterday"
      base_query = base_query.where(created_at: Date.yesterday.beginning_of_day..Date.yesterday.end_of_day)
    when "this_week"
      base_query = base_query.where("created_at >= ?", Date.current.beginning_of_week)
    when "this_month"
      base_query = base_query.where("created_at >= ?", Date.current.beginning_of_month)
    when "last_month"
      base_query = base_query.where(created_at: Date.current.last_month.beginning_of_month..Date.current.last_month.end_of_month)
    when "custom"
      if params[:start_date].present? && params[:end_date].present?
        start_date = Date.parse(params[:start_date]).beginning_of_day
        end_date = Date.parse(params[:end_date]).end_of_day
        base_query = base_query.where(created_at: start_date..end_date)
      end
    end

    # Apply text search if provided (searches description and reference_number)
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      base_query = base_query.where("description ILIKE ? OR reference_number ILIKE ?", search_term, search_term)
    end

    # Order and paginate results using Pagy
    @pagy, @transactions = pagy(base_query.order(created_at: :desc), items: Rails.application.config.x.wallet[:pagination_items_per_page] || 20)
  end

  def send_money
    @recent_recipients = current_user.beneficiaries.order(created_at: :desc).limit(Rails.application.config.x.wallet[:send_money_recent_recipients_count] || 10)
  end

  def process_send_money
    # Get parameters
    recipient_wallet_id = params[:account_number]
    amount = params[:amount].to_f
    description = params[:description]

    # Validate parameters
    if recipient_wallet_id.blank?
      flash[:error] = "Recipient account number is required"
      return redirect_to send_money_path
    end

    if amount <= 0
      flash[:error] = "Please enter a valid amount"
      return redirect_to send_money_path
    end

    # Find recipient wallet
    recipient_wallet = Wallet.find_by(wallet_id: recipient_wallet_id)

    if recipient_wallet.nil?
      flash[:error] = "Recipient account not found"
      return redirect_to send_money_path
    end

    # Don't allow sending to self
    if recipient_wallet.id == @wallet.id
      flash[:error] = "Cannot send money to yourself"
      return redirect_to send_money_path
    end

    # Check if user has sufficient balance
    if amount > @wallet.balance
      flash[:error] = "Insufficient funds"
      return redirect_to send_money_path
    end

    # Create the transfer transaction
    transaction = Transaction.create_transfer(
      source_wallet: @wallet,
      destination_wallet: recipient_wallet,
      amount: amount,
      description: description || "Transfer to #{recipient_wallet.user.display_name || 'recipient'}"
    )

    if transaction.persisted?
      # Run security checks
      security_passed = transaction.security_check(current_user, request.remote_ip, request.user_agent)

      unless security_passed
        flash[:error] = "Transaction blocked due to security concerns. Please contact support."
        return redirect_to wallet_path
      end

      # Process the transfer
      service = TransactionService.new(
        transaction,
        current_user,
        request.remote_ip,
        request.user_agent
      )

      result = service.process

      if result[:success]
        flash[:success] = "Successfully transferred #{transaction.formatted_amount} to #{recipient_wallet.user.display_name || 'recipient'}"
      else
        flash[:warning] = "Your transfer is being processed"
      end

      redirect_to wallet_path
    else
      flash[:error] = "Failed to create transaction: #{transaction.errors.full_messages.join(', ')}"
      redirect_to send_money_path
    end
  end

  def receive_money
    # Get recent deposits using the wallet's received_transactions association
    recent_count = Rails.application.config.x.wallet[:dashboard_recent_transactions_count] || 5
    @recent_deposits = @wallet.received_transactions.where(transaction_type: "deposit").order(created_at: :desc).limit(recent_count)

    # Set the active tab based on the parameter or default to 'account_details'
    @active_tab = params[:tab] || "account_details"

    # Generate payment link for the user
    @payment_link = payment_link_for_user(current_user)

    # Generate QR code data - just use the payment link directly for simplicity
    # This reduces the QR code complexity and makes it easier to scan
    @qr_code_data = @payment_link

    # Initialize empty array for recent payment links
    # In a real app, this would fetch from a PaymentLink model
    @recent_payment_links = []
  end

  def pay_bill
    begin
      if defined?(BillPayment) && ActiveRecord::Base.connection.table_exists?(:bill_payments)
        recent_count = Rails.application.config.x.wallet[:dashboard_recent_transactions_count] || 5
        @recent_bill_payments = current_user.bill_payments.where(bill_type: params[:type]).order(created_at: :desc).limit(recent_count)
      else
        @recent_bill_payments = []
        Rails.logger.warn("BillPayment model or table not found in pay_bill action")
      end
    rescue => e
      @recent_bill_payments = []
      Rails.logger.error("Error in pay_bill action: #{e.message}\n#{e.backtrace.join("\n")}")
    end
  end

  def beneficiaries
    # Get all beneficiaries for the user
    base_query = current_user.beneficiaries

    # Apply filters if provided
    if params[:transfer_type].present? && params[:transfer_type] != "all"
      base_query = base_query.where(transfer_type: params[:transfer_type])
    end

    # Apply sorting
    case params[:sort_by]
    when "name"
      base_query = base_query.order(name: :asc)
    when "frequently_used"
      base_query = base_query.order(usage_count: :desc)
    else # recent
      base_query = base_query.order(created_at: :desc)
    end

    # Apply search if provided
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      base_query = base_query.where("name ILIKE ? OR account_number ILIKE ? OR phone_number ILIKE ?",
                                   search_term, search_term, search_term)
    end

    # Paginate results using Pagy
    @beneficiaries = base_query.to_a
    # For now, we'll just return all beneficiaries without pagination
    # In a real app, you would use Pagy like this:
    # @pagy, @beneficiaries = pagy(base_query, items: Rails.application.config.x.wallet[:pagination_items_per_page] || 20)
  end

  def new_beneficiary
    @beneficiary = Beneficiary.new
  end

  def create_beneficiary
    @beneficiary = current_user.beneficiaries.new(beneficiary_params)

    if @beneficiary.save
      flash[:success] = "Beneficiary added successfully"
      redirect_to beneficiaries_path
    else
      flash.now[:error] = @beneficiary.errors.full_messages.to_sentence
      render :new_beneficiary
    end
  end

  def process_bill_payment
    # Get parameters
    bill_type = params[:bill_type]
    provider = params[:provider]
    account_number = params[:account_number]
    amount = params[:amount].to_f

    # Validate parameters
    if bill_type.blank? || provider.blank? || account_number.blank?
      flash[:error] = "Please fill in all required fields"
      return redirect_to bills_path
    end

    if amount <= 0
      flash[:error] = "Please enter a valid amount"
      return redirect_to bills_path
    end

    # Check if user has sufficient balance
    if amount > @wallet.balance
      flash[:error] = "Insufficient funds"
      return redirect_to bills_path
    end

    # Create a system wallet for bill payments if it doesn't exist
    system_wallet_id = Rails.application.config.x.wallet[:system_wallet_id]
    system_wallet = Wallet.find_by(wallet_id: system_wallet_id)
    unless system_wallet
      system_wallet = Wallet.create!(
        user: User.find_by(email: Rails.application.config.x.wallet[:system_user_email]) || User.first,
        wallet_id: system_wallet_id,
        status: :active,
        balance: Rails.application.config.x.wallet[:default_initial_balance],
        currency: Rails.application.config.x.wallet[:default_currency],
        daily_limit: Rails.application.config.x.wallet[:system_wallet_daily_limit]
      )
    end

    # Create the payment transaction
    transaction = Transaction.create_payment(
      source_wallet: @wallet,
      destination_wallet: system_wallet,
      amount: amount,
      description: "#{bill_type.titleize} payment to #{provider} (#{account_number})",
      metadata: {
        bill_type: bill_type,
        provider: provider,
        account_number: account_number
      }
    )

    if transaction.persisted?
      # Run security checks
      security_passed = transaction.security_check(current_user, request.remote_ip, request.user_agent)

      unless security_passed
        flash[:error] = "Transaction blocked due to security concerns. Please contact support."
        return redirect_to wallet_path
      end

      # Process the payment
      service = TransactionService.new(
        transaction,
        current_user,
        request.remote_ip,
        request.user_agent
      )

      result = service.process

      # Create bill payment record if the model exists
      if defined?(BillPayment) && result[:success]
        BillPayment.create(
          user: current_user,
          transaction: transaction,
          bill_type: bill_type,
          provider: provider,
          account_number: account_number,
          amount: amount,
          status: :completed
        )
      end

      if result[:success]
        flash[:success] = "Bill payment successful! #{transaction.formatted_amount} paid to #{provider}"
      else
        flash[:warning] = "Your bill payment is being processed"
      end

      redirect_to wallet_path
    else
      flash[:error] = "Failed to create transaction: #{transaction.errors.full_messages.join(', ')}"
      redirect_to bills_path
    end
  end

  def bills
    # Get recent bill payments across all types
    begin
      if defined?(BillPayment) && ActiveRecord::Base.connection.table_exists?(:bill_payments)
        recent_count = Rails.application.config.x.wallet[:send_money_recent_recipients_count] || 10
        @recent_bill_payments = current_user.bill_payments.order(created_at: :desc).limit(recent_count)
      else
        @recent_bill_payments = []
        Rails.logger.warn("BillPayment model or table not found")
      end
    rescue => e
      @recent_bill_payments = []
      Rails.logger.error("Error in bills action: #{e.message}\n#{e.backtrace.join("\n")}")
    end
  end

  def airtime
    # Get recent airtime purchases
    begin
      if defined?(BillPayment) && ActiveRecord::Base.connection.table_exists?(:bill_payments)
        recent_count = Rails.application.config.x.wallet[:send_money_recent_recipients_count] || 10
        @recent_bill_payments = current_user.bill_payments.where(bill_type: 'airtime').order(created_at: :desc).limit(recent_count)
      else
        @recent_bill_payments = []
        Rails.logger.warn("BillPayment model or table not found in airtime action")
      end
    rescue => e
      @recent_bill_payments = []
      Rails.logger.error("Error in airtime action: #{e.message}\n#{e.backtrace.join("\n")}")
    end

    # Render the airtime template
    render :airtime
  end

  # Generate a payment link for a user
  def payment_link_for_user(user)
    # Generate a payment link for the user
    # This would typically include the user's wallet ID or other identifier
    wallet = user.wallet

    # Base URL for the payment
    base_url = request.base_url

    # Create the payment link
    "#{base_url}/pay/#{wallet.wallet_id}"
  end

  # Payment page for receiving money via a shared link
  def payment_page
    # Find the wallet by wallet_id
    @recipient_wallet = Wallet.find_by(wallet_id: params[:wallet_id])

    if @recipient_wallet.nil?
      flash[:error] = "Invalid payment link. The recipient could not be found."
      redirect_to root_path
      return
    end

    # Get the recipient user
    @recipient = User.find(@recipient_wallet.user_id)

    # Initialize payment amount
    @amount = params[:amount].present? ? params[:amount].to_f : nil

    # If user is logged in, get their wallet for sending money
    if user_signed_in?
      @sender_wallet = current_user.wallet
    end
  end

  private

  # Generate a payment link for a user
  def payment_link_for_user(user)
    wallet = user.wallet
    return nil unless wallet

    # Generate a URL to the payment page with the wallet ID
    payment_page_url(wallet_id: wallet.wallet_id, host: request.host_with_port)
  end

  def set_wallet
    # Ensure current_user is present
    return redirect_to new_user_session_path unless current_user

    # Get the user's wallet safely
    begin
      # Try to find the wallet directly from the database
      @wallet = current_user.wallet

      # If user doesn't have a wallet yet, create one
      unless @wallet
        # Generate a unique wallet ID
        prefix = Rails.application.config.x.wallet[:wallet_id_prefix]
        length = Rails.application.config.x.wallet[:wallet_id_random_length]
        wallet_id = "#{prefix}#{SecureRandom.alphanumeric(length).upcase}"

        # Create the wallet with all required attributes
        @wallet = Wallet.create!(
          user: current_user,
          wallet_id: wallet_id,
          status: :active,
          balance: Rails.application.config.x.wallet[:default_initial_balance],
          currency: Rails.application.config.x.wallet[:default_currency],
          daily_limit: Rails.application.config.x.wallet[:default_daily_limit]
        )

        Rails.logger.info("Created new wallet #{wallet_id} for user #{current_user.id}")
      end
    rescue => e
      # Log the error
      Rails.logger.error("Error in set_wallet: #{e.message}\n#{e.backtrace.join("\n")}")

      # Create a temporary wallet object to prevent errors
      prefix = Rails.application.config.x.wallet[:wallet_id_prefix]
      length = Rails.application.config.x.wallet[:wallet_id_random_length]
      @wallet = Wallet.new(
        user: current_user,
        wallet_id: "TEMP-#{SecureRandom.alphanumeric(length).upcase}",
        status: :active,
        balance: Rails.application.config.x.wallet[:default_initial_balance],
        currency: Rails.application.config.x.wallet[:default_currency],
        daily_limit: Rails.application.config.x.wallet[:default_daily_limit]
      )
    end
  end

  def beneficiary_params
    params.require(:beneficiary).permit(
      :name, :account_number, :bank_name, :phone_number,
      :transfer_type, :avatar
    )
  end

  def bill_payment_params
    params.require(:bill_payment).permit(
      :bill_type, :provider, :account_number, :package, :amount
    )
  end
end
