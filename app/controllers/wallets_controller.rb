class WalletsController < ApplicationController
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
        next: page * items < total ? page + 1 : nil
      )

      return pagy_obj, subset
    end

    def pagy_info(pagy)
      "#{pagy.page}/#{pagy.pages} pages"
    end

    def pagy_nav(pagy)
      # Simple navigation
      html = '<div class="flex space-x-2">'
      if pagy.prev
        html += "<a href=\"?page=#{pagy.prev}\" class=\"px-3 py-1 rounded bg-gray-200\">Prev</a>"
      else
        html += "<span class=\"px-3 py-1 rounded bg-gray-100 opacity-50\">Prev</span>"
      end

      html += "<span class=\"px-3 py-1 rounded bg-primary-600 text-white\">#{pagy.page}</span>"

      if pagy.next
        html += "<a href=\"?page=#{pagy.next}\" class=\"px-3 py-1 rounded bg-gray-200\">Next</a>"
      else
        html += "<span class=\"px-3 py-1 rounded bg-gray-100 opacity-50\">Next</span>"
      end

      html += "</div>"
      html.html_safe
    end
  end
  # Include Pagy for pagination
  before_action :authenticate_user!
  before_action :set_wallet, only: [ :show, :edit, :update ]
  before_action :ensure_wallet_ownership, only: [ :show, :edit, :update ]

  # Dashboard page showing wallet overview
  def show
    @recent_transactions = @wallet.recent_transactions(10)

    # Calculate stats for summary cards
    @today_incoming = @wallet.total_incoming(start_date: Date.current, end_date: Date.current)
    @today_outgoing = @wallet.total_outgoing(start_date: Date.current, end_date: Date.current)

    @this_month_incoming = @wallet.total_incoming(
      start_date: Date.current.beginning_of_month,
      end_date: Date.current.end_of_month
    )
    @this_month_outgoing = @wallet.total_outgoing(
      start_date: Date.current.beginning_of_month,
      end_date: Date.current.end_of_month
    )

    # Get active payment methods for quick actions
    @payment_methods = current_user.payment_methods.active_methods.verified_methods.order(default: :desc)
  end

  # New transaction form
  def new_transaction
    @wallet = current_user.wallet
    @transaction_type = params[:type] || "deposit"
    @payment_methods = current_user.payment_methods.active_methods.verified_methods

    # Different data needed based on transaction type
    case @transaction_type
    when "transfer"
      # For transfers, we need recipient data
      @recent_recipients = Transaction.successful
                                     .where(transaction_type: :transfer, source_wallet_id: @wallet.id)
                                     .includes(destination_wallet: :user)
                                     .order(created_at: :desc)
                                     .limit(5)
                                     .map { |t| t.destination_wallet.user }
                                     .uniq
    end

    # Initialize new transaction
    @transaction = Transaction.new
  end

  # Process a deposit
  def deposit
    @wallet = current_user.wallet
    amount = params[:amount].to_f
    payment_method_id = params[:payment_method_id]
    description = params[:description]

    # Validate inputs
    if amount <= 0
      flash[:error] = "Amount must be greater than zero"
      redirect_to new_transaction_wallet_path(type: "deposit")
      return
    end

    if payment_method_id.blank?
      flash[:error] = "Please select a payment method"
      redirect_to new_transaction_wallet_path(type: "deposit")
      return
    end

    # Get payment method details
    payment_method = current_user.payment_methods.find_by(id: payment_method_id)
    unless payment_method
      flash[:error] = "Invalid payment method"
      redirect_to new_transaction_wallet_path(type: "deposit")
      return
    end

    # Create deposit transaction
    transaction = Transaction.create_deposit(
      wallet: @wallet,
      amount: amount,
      payment_method: payment_method.method_type,
      provider: payment_method.provider,
      metadata: {
        payment_method_id: payment_method.id,
        description: description,
        user_agent: request.user_agent,
        ip_address: request.remote_ip
      }
    )

    if transaction.persisted?
      # Mark payment method as used
      payment_method.mark_as_used!

      # Here, you would typically initiate the actual payment process
      # For simplicity, we'll simulate an instant success
      if transaction.complete!
        flash[:success] = "Successfully deposited #{transaction.formatted_amount} to your wallet"
      else
        flash[:warning] = "Your deposit is being processed"
      end

      redirect_to wallet_path
    else
      flash[:error] = "Failed to create transaction: #{transaction.errors.full_messages.join(', ')}"
      redirect_to new_transaction_wallet_path(type: "deposit")
    end
  end

  # Process a withdrawal
  def withdraw
    @wallet = current_user.wallet
    amount = params[:amount].to_f
    payment_method_id = params[:payment_method_id]
    description = params[:description]

    # Validate inputs
    if amount <= 0
      flash[:error] = "Amount must be greater than zero"
      redirect_to new_transaction_wallet_path(type: "withdrawal")
      return
    end

    if amount > @wallet.balance
      flash[:error] = "Insufficient balance for this withdrawal"
      redirect_to new_transaction_wallet_path(type: "withdrawal")
      return
    end

    if payment_method_id.blank?
      flash[:error] = "Please select a payment method"
      redirect_to new_transaction_wallet_path(type: "withdrawal")
      return
    end

    # Get payment method details
    payment_method = current_user.payment_methods.find_by(id: payment_method_id)
    unless payment_method
      flash[:error] = "Invalid payment method"
      redirect_to new_transaction_wallet_path(type: "withdrawal")
      return
    end

    # Check daily limit
    if @wallet.daily_limit_exceeded?(amount)
      flash[:error] = "This withdrawal would exceed your daily transaction limit"
      redirect_to new_transaction_wallet_path(type: "withdrawal")
      return
    end

    # Create withdrawal transaction
    transaction = Transaction.create_withdrawal(
      wallet: @wallet,
      amount: amount,
      payment_method: payment_method.method_type,
      provider: payment_method.provider,
      metadata: {
        payment_method_id: payment_method.id,
        description: description,
        user_agent: request.user_agent,
        ip_address: request.remote_ip
      }
    )

    if transaction.persisted?
      # Mark payment method as used
      payment_method.mark_as_used!

      # Here, you would typically initiate the actual withdrawal process
      # For simplicity, we'll simulate an instant success
      if transaction.complete!
        flash[:success] = "Successfully withdrew #{transaction.formatted_amount} from your wallet"
      else
        flash[:warning] = "Your withdrawal is being processed"
      end

      redirect_to wallet_path
    else
      flash[:error] = "Failed to create transaction: #{transaction.errors.full_messages.join(', ')}"
      redirect_to new_transaction_wallet_path(type: "withdrawal")
    end
  end

  # Process a transfer
  def transfer
    @wallet = current_user.wallet
    amount = params[:amount].to_f
    recipient_identifier = params[:recipient]
    description = params[:description]

    # Validate inputs
    if amount <= 0
      flash[:error] = "Amount must be greater than zero"
      redirect_to new_transaction_wallet_path(type: "transfer")
      return
    end

    if amount > @wallet.balance
      flash[:error] = "Insufficient balance for this transfer"
      redirect_to new_transaction_wallet_path(type: "transfer")
      return
    end

    if recipient_identifier.blank?
      flash[:error] = "Please specify a recipient"
      redirect_to new_transaction_wallet_path(type: "transfer")
      return
    end

    # Find recipient by phone, username, or email
    recipient = User.find_by("phone = ? OR username = ? OR email = ?",
                            recipient_identifier, recipient_identifier, recipient_identifier)

    unless recipient
      flash[:error] = "Recipient not found"
      redirect_to new_transaction_wallet_path(type: "transfer")
      return
    end

    # Prevent self-transfers
    if recipient.id == current_user.id
      flash[:error] = "You can't transfer to yourself"
      redirect_to new_transaction_wallet_path(type: "transfer")
      return
    end

    # Check if recipient has an active wallet
    recipient_wallet = recipient.wallet
    unless recipient_wallet&.active?
      flash[:error] = "Recipient doesn't have an active wallet"
      redirect_to new_transaction_wallet_path(type: "transfer")
      return
    end

    # Check daily limit
    if @wallet.daily_limit_exceeded?(amount)
      flash[:error] = "This transfer would exceed your daily transaction limit"
      redirect_to new_transaction_wallet_path(type: "transfer")
      return
    end

    # Create transfer transaction
    transaction = Transaction.create_transfer(
      source_wallet: @wallet,
      destination_wallet: recipient_wallet,
      amount: amount,
      description: description,
      metadata: {
        sender_name: current_user.display_name,
        recipient_name: recipient.display_name,
        user_agent: request.user_agent,
        ip_address: request.remote_ip
      }
    )

    if transaction.persisted?
      # Process the transfer
      if transaction.complete!
        flash[:success] = "Successfully transferred #{transaction.formatted_amount} to #{recipient.display_name}"
      else
        flash[:warning] = "Your transfer is being processed"
      end

      redirect_to wallet_path
    else
      flash[:error] = "Failed to create transaction: #{transaction.errors.full_messages.join(', ')}"
      redirect_to new_transaction_wallet_path(type: "transfer")
    end
  end

  # Transaction history with filtering
  def transactions
    @wallet = current_user.wallet

    # Apply filters
    @filter_type = params[:type]
    @filter_status = params[:status]
    @filter_start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : 30.days.ago.to_date
    @filter_end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current

    # Build query
    transactions_query = Transaction.where("source_wallet_id = ? OR destination_wallet_id = ?", @wallet.id, @wallet.id)

    # Apply type filter if specified
    transactions_query = transactions_query.where(transaction_type: @filter_type) if @filter_type.present?

    # Apply status filter if specified
    transactions_query = transactions_query.where(status: @filter_status) if @filter_status.present?

    # Apply date range filter
    transactions_query = transactions_query.by_date_range(@filter_start_date, @filter_end_date)

    # Order by date, newest first
    transactions_query = transactions_query.order(created_at: :desc)

    # Paginate results - try to use Pagy if available
    begin
      # Pagination with Pagy
      @pagy, @transactions = pagy(transactions_query, items: 20)
    rescue NameError => e
      # Fallback to traditional pagination if Pagy not available
      page = (params[:page] || 1).to_i
      per_page = 20
      offset = (page - 1) * per_page

      @transactions = transactions_query.offset(offset).limit(per_page)
      total_count = transactions_query.count

      # Create a simple pagination struct
      @pagy = OpenStruct.new(
        count: total_count,
        page: page,
        items: per_page,
        pages: (total_count.to_f / per_page).ceil
      )
    end

    # Calculate summary statistics for the filtered transactions
    @total_incoming = Transaction.successful
                               .where(destination_wallet_id: @wallet.id)
                               .by_date_range(@filter_start_date, @filter_end_date)
                               .sum(:amount)

    @total_outgoing = Transaction.successful
                               .where(source_wallet_id: @wallet.id)
                               .by_date_range(@filter_start_date, @filter_end_date)
                               .sum(:amount)
  end

  # Show details for a specific transaction
  def transaction_details
    @wallet = current_user.wallet
    @transaction = Transaction.find_by(id: params[:id])

    # Ensure user can only view their own transactions
    unless @transaction && (@transaction.source_wallet_id == @wallet.id || @transaction.destination_wallet_id == @wallet.id)
      flash[:error] = "Transaction not found"
      redirect_to transactions_wallet_path
      nil
    end
  end

  # AJAX endpoint to refresh wallet balance
  def refresh_balance
    @wallet = current_user.wallet

    respond_to do |format|
      format.json { render json: { balance: @wallet.balance, formatted_balance: @wallet.formatted_balance } }
    end
  end

  # AJAX endpoint to get recent transactions
  def recent_transactions
    @wallet = current_user.wallet
    @recent_transactions = @wallet.recent_transactions(10)

    respond_to do |format|
      format.html { render partial: "recent_transactions", locals: { recent_transactions: @recent_transactions } }
    end
  end

  def edit
    @wallet = current_user.wallet
  end

  def update
    @wallet = current_user.wallet
    if @wallet.update(wallet_params)
      flash[:success] = "Wallet updated successfully"
      redirect_to wallet_path
    else
        render "edit"
    end
  end


  private

  # Set wallet from user association
  def set_wallet
    @wallet = current_user.wallet

    # If user doesn't have a wallet yet, create one
    unless @wallet
      @wallet = Wallet.create(
        user: current_user,
        wallet_id: "W#{SecureRandom.alphanumeric(12).upcase}",
        status: :active,
        balance: 0,
        currency: "GHS",
        daily_limit: 1000
      )
    end
  end

  # Ensure user can only access their own wallet
  def ensure_wallet_ownership
    unless @wallet&.user_id == current_user.id
      flash[:error] = "You don't have permission to access this wallet"
      redirect_to root_path
    end
  end
end
