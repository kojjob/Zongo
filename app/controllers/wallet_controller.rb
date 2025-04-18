class WalletController < ApplicationController
  require "securerandom"

  before_action :authenticate_user!
  before_action :set_wallet

  def dashboard
    # Get recent transactions
    @recent_transactions = @wallet.recent_transactions(5)

    # Get beneficiaries - handle case where beneficiaries might not exist yet
    @beneficiaries = if current_user.respond_to?(:beneficiaries)
                      current_user.beneficiaries.order(created_at: :desc).limit(5)
    else
                      []
    end

    # Calculate savings and spending
    @savings_total = @wallet.total_incoming(start_date: 30.days.ago, end_date: Date.current)
    @spending_total = @wallet.total_outgoing(start_date: 30.days.ago, end_date: Date.current)

    # Calculate percentage changes (example calculation - would be based on previous period in real app)
    @savings_change = 16.8 # Placeholder value
    @spending_change = -16.8 # Placeholder value
  end

  # Include Pagy for pagination if available
  begin
    require "pagy"
    include Pagy::Backend
  rescue LoadError
    # Fallback method if Pagy is not available
    def pagy(collection, options = {})
      items = options[:items] || 20
      page = (params[:page] || 1).to_i

      total = collection.count
      offset = (page - 1) * items
      subset = collection.offset(offset).limit(items)

      # Simple OpenStruct to mimic Pagy behavior
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

  def transactions
    # Get all transactions for the user
    start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 90.days.ago.to_date
    end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current

    # Use wallet's transaction_history method
    base_query = @wallet.transaction_history(start_date: start_date, end_date: end_date)

    # Apply filters if provided
    if params[:transaction_type].present? && params[:transaction_type] != "all"
      base_query = base_query.where(transaction_type: params[:transaction_type])
    end

    if params[:status].present? && params[:status] != "all"
      base_query = base_query.where(status: params[:status])
    end

    # Apply date range filter
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

    # Apply search if provided
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      base_query = base_query.where("description ILIKE ? OR reference_number ILIKE ?", search_term, search_term)
    end

    # Order and paginate results using Pagy
    @pagy, @transactions = pagy(base_query.order(created_at: :desc), items: 20)
  end

  def send_money
    @recent_recipients = current_user.beneficiaries.order(created_at: :desc).limit(10)
  end

  def process_send_money
    # Process the money transfer
    # This would include validation, creating a transaction record, etc.

    # Placeholder for demonstration
    flash[:notice] = "Money sent successfully!"
    redirect_to wallet_path
  end

  def receive_money
    # Get recent deposits using the wallet's received_transactions association
    @recent_deposits = @wallet.received_transactions.where(transaction_type: "deposit").order(created_at: :desc).limit(5)

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
        @recent_bill_payments = current_user.bill_payments.where(bill_type: params[:type]).order(created_at: :desc).limit(5)
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
    # @pagy, @beneficiaries = pagy(base_query, items: 12)
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
    # Process the bill payment
    # This would include validation, creating a bill payment record, etc.

    # Placeholder for demonstration
    flash[:notice] = "Bill payment successful!"
    redirect_to wallet_path
  end

  def bills
    # Get recent bill payments across all types
    begin
      if defined?(BillPayment) && ActiveRecord::Base.connection.table_exists?(:bill_payments)
        @recent_bill_payments = current_user.bill_payments.order(created_at: :desc).limit(10)
      else
        @recent_bill_payments = []
        Rails.logger.warn("BillPayment model or table not found")
      end
    rescue => e
      @recent_bill_payments = []
      Rails.logger.error("Error in bills action: #{e.message}\n#{e.backtrace.join("\n")}")
    end
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

  def set_wallet
    # Ensure current_user is present
    return redirect_to new_user_session_path unless current_user

    # Get the user's wallet safely
    begin
      # Try to find the wallet directly from the database to avoid any method overrides
      @wallet = Wallet.find_by(user_id: current_user.id)

      # If user doesn't have a wallet yet, create one
      unless @wallet
        # Generate a unique wallet ID
        wallet_id = "W#{SecureRandom.hex(6).upcase}"

        # Create the wallet with all required attributes
        @wallet = Wallet.create!(
          user_id: current_user.id,  # Use user_id directly instead of user association
          wallet_id: wallet_id,
          status: :active,
          balance: 0,
          currency: "GHS",
          daily_limit: 1000
        )

        Rails.logger.info("Created new wallet #{wallet_id} for user #{current_user.id}")
      end
    rescue => e
      # Log the error
      Rails.logger.error("Error in set_wallet: #{e.message}\n#{e.backtrace.join("\n")}")

      # Create a temporary wallet object to prevent errors
      @wallet = Wallet.new(
        user_id: current_user.id,
        wallet_id: "TEMP-#{SecureRandom.hex(6).upcase}",
        status: :active,
        balance: 0,
        currency: "GHS",
        daily_limit: 1000
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
