class TransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transaction, only: [ :show, :process_transaction, :reverse ]
  before_action :authorize_transaction, only: [ :show, :process_transaction, :reverse ]

  include ResultHandler
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
    result = case transaction_params[:transaction_type]
    when "deposit"
      TransactionService.create_deposit(
        wallet: source_wallet,
        amount: transaction_params[:amount].to_f,
        payment_method: transaction_params[:payment_method],
        provider: transaction_params[:provider],
        metadata: { destination: transaction_params[:destination] }
      )
    when "withdrawal"
      TransactionService.create_withdrawal(
        wallet: source_wallet,
        amount: transaction_params[:amount].to_f,
        payment_method: transaction_params[:payment_method],
        provider: transaction_params[:provider],
        metadata: { destination: transaction_params[:destination] }
      )
    when "transfer"
      destination_wallet = Wallet.find(transaction_params[:destination_wallet_id])
      TransactionService.create_transfer(
        source_wallet: source_wallet,
        destination_wallet: destination_wallet,
        amount: transaction_params[:amount].to_f,
        description: transaction_params[:description]
      )
    when "payment"
      destination_wallet = Wallet.find(transaction_params[:destination_wallet_id])
      TransactionService.create_transfer(
        source_wallet: source_wallet,
        destination_wallet: destination_wallet,
        amount: transaction_params[:amount].to_f,
        description: transaction_params[:description],
        metadata: {
          destination: transaction_params[:destination],
          transaction_type: "payment"
        }
      )
    else
      Result.failure(ValidationError.new("Invalid transaction type"))
    end

    handle_result(result) do |data|
      @transaction = data[:transaction]

      # Perform security check
      if @transaction.security_check(current_user, request.remote_ip, request.user_agent)
        # Process the transaction
        process_result = process_transaction_with_service(@transaction)

        handle_result(process_result,
          success_redirect: transaction_path(@transaction),
          success_message: "Transaction processed successfully",
          failure_redirect: transaction_path(@transaction)
        )
      else
        handle_result(
          Result.failure(SecurityViolationError.new("Transaction blocked by security checks")),
          failure_redirect: transaction_path(@transaction)
        )
      end
    end
  end

  # POST /transactions/:id/process
  def process_transaction
    # Only process pending transactions
    unless @transaction.status_pending?
      error = BusinessRuleError.new(
        "Transaction cannot be processed in its current state",
        :invalid_transaction_state
      )
      return handle_result(Result.failure(error),
        failure_redirect: transaction_path(@transaction)
      )
    end

    # Process the transaction
    process_result = process_transaction_with_service(@transaction)

    handle_result(process_result,
      success_redirect: transaction_path(@transaction),
      success_message: "Transaction processed successfully",
      failure_redirect: transaction_path(@transaction)
    )
  end

  # POST /transactions/:id/reverse
  def reverse
    # Only reverse completed transactions
    unless @transaction.status_completed?
      error = BusinessRuleError.new(
        "Transaction cannot be reversed in its current state",
        :invalid_transaction_state
      )
      return handle_result(Result.failure(error),
        failure_redirect: transaction_path(@transaction)
      )
    end

    # Reverse the transaction
    if @transaction.reverse!(reason: params[:reason])
      handle_result(Result.success({message: "Transaction reversed successfully"}),
        success_redirect: transaction_path(@transaction)
      )
    else
      error = BusinessRuleError.new("Failed to reverse transaction", :reversal_failed)
      handle_result(Result.failure(error),
        failure_redirect: transaction_path(@transaction)
      )
    end
  end

  private

  # Set the transaction from the ID parameter
  def set_transaction
    result = TransactionService.find_by_id(params[:id])

    handle_result(result,
      success_action: :render,
      failure_redirect: wallet_path,
      skip_flash: true
    ) do |data|
      @transaction = data[:transaction]
    end
  end

  # Authorize the user to access the transaction
  def authorize_transaction
    authorize_resource(@transaction, "You are not authorized to access this transaction")
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
