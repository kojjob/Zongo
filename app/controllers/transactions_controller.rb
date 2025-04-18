class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction, only: [ :show, :process_transaction, :reverse ]
  before_action :authorize_transaction, only: [ :show, :process_transaction, :reverse ]

  include Pagy::Backend

  # GET /transactions
  def index
    @pagy, @transactions = pagy(current_user.transactions.recent, items: 20)
  end

  # GET /transactions/:id
  def show
    # Transaction details are loaded in set_transaction
  end

  # GET /transactions/new
  def new
    @transaction_type = params[:type] || "transfer"
    @transaction = Transaction.new(transaction_type: @transaction_type)
  end

  # POST /transactions
  def create
    transaction_params = params.require(:transaction).permit(
      :transaction_type, :amount, :destination_wallet_id, :description,
      :payment_method, :provider, destination: {}
    )

    # Get the source wallet (current user's wallet)
    source_wallet = current_user.wallet

    # Create the appropriate transaction based on type
    case transaction_params[:transaction_type]
    when "deposit"
      @transaction = Transaction.create_deposit(
        wallet: source_wallet,
        amount: transaction_params[:amount].to_f,
        payment_method: transaction_params[:payment_method],
        provider: transaction_params[:provider],
        metadata: { destination: transaction_params[:destination] }
      )
    when "withdrawal"
      @transaction = Transaction.create_withdrawal(
        wallet: source_wallet,
        amount: transaction_params[:amount].to_f,
        payment_method: transaction_params[:payment_method],
        provider: transaction_params[:provider],
        metadata: { destination: transaction_params[:destination] }
      )
    when "transfer"
      destination_wallet = Wallet.find(transaction_params[:destination_wallet_id])
      @transaction = Transaction.create_transfer(
        source_wallet: source_wallet,
        destination_wallet: destination_wallet,
        amount: transaction_params[:amount].to_f,
        description: transaction_params[:description]
      )
    when "payment"
      destination_wallet = Wallet.find(transaction_params[:destination_wallet_id])
      @transaction = Transaction.create_payment(
        source_wallet: source_wallet,
        destination_wallet: destination_wallet,
        amount: transaction_params[:amount].to_f,
        description: transaction_params[:description],
        metadata: { destination: transaction_params[:destination] }
      )
    else
      return redirect_to wallet_path, alert: "Invalid transaction type"
    end

    # --- Debug Logging Start ---
    Rails.logger.debug "Transaction object before persist check: #{@transaction.inspect}"
    Rails.logger.debug "Transaction valid?: #{@transaction.valid?}"
    Rails.logger.debug "Transaction errors: #{@transaction.errors.full_messages.join(', ')}" unless @transaction.valid?
    # --- Debug Logging End ---

    if @transaction&.persisted? # Added safe navigation just in case @transaction is nil
      # Perform security check
      if @transaction.security_check(current_user, request.remote_ip, request.user_agent)
        # Process the transaction
        process_result = process_transaction_with_service(@transaction)

        if process_result[:success]
          redirect_to transaction_path(@transaction), notice: "Transaction created successfully"
        else
          redirect_to transaction_path(@transaction), alert: process_result[:message]
        end
      else
        redirect_to transaction_path(@transaction), alert: "Transaction blocked by security checks"
      end
    else
      # --- Debug Logging Start ---
      Rails.logger.error "Failed to persist transaction. Errors: #{@transaction&.errors&.full_messages&.join(', ')}"
      # --- Debug Logging End ---
      redirect_to wallet_path, alert: "Failed to create transaction: #{@transaction&.errors&.full_messages&.join(', ')}" # Add errors to alert
    end
  end

  # POST /transactions/:id/process
  def process_transaction
    # Only process pending transactions
    unless @transaction.status_pending?
      return redirect_to transaction_path(@transaction), alert: "Transaction cannot be processed"
    end

    # Process the transaction
    process_result = process_transaction_with_service(@transaction)

    if process_result[:success]
      redirect_to transaction_path(@transaction), notice: "Transaction processed successfully"
    else
      redirect_to transaction_path(@transaction), alert: process_result[:message]
    end
  end

  # POST /transactions/:id/reverse
  def reverse
    # Only reverse completed transactions
    unless @transaction.status_completed?
      return redirect_to transaction_path(@transaction), alert: "Transaction cannot be reversed"
    end

    # Reverse the transaction
    if @transaction.reverse!(reason: params[:reason])
      redirect_to transaction_path(@transaction), notice: "Transaction reversed successfully"
    else
      redirect_to transaction_path(@transaction), alert: "Failed to reverse transaction"
    end
  end

  private

  # Set the transaction from the ID parameter
  def set_transaction
    @transaction = Transaction.find(params[:id])
  end

  # Authorize the user to access the transaction
  def authorize_transaction
    # Check if the user is associated with the transaction
    unless @transaction.sender == current_user || @transaction.recipient == current_user
      redirect_to wallet_path, alert: "You are not authorized to access this transaction"
    end
  end

  # Process a transaction using the TransactionService
  def process_transaction_with_service(transaction)
    # Create a transaction service
    service = TransactionService.new(
      transaction,
      current_user,
      request.remote_ip,
      request.user_agent
    )

    # Process the transaction
    verification_data = params[:verification_data] || {}
    external_reference = params[:external_reference]

    service.process(
      external_reference: external_reference,
      verification_data: verification_data
    )
  end
end
