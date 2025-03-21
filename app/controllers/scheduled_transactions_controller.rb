class ScheduledTransactionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_wallet
  before_action :set_scheduled_transaction, only: [ :show, :edit, :update, :destroy, :pause, :resume, :execute ]
  before_action :ensure_ownership, only: [ :show, :edit, :update, :destroy, :pause, :resume, :execute ]

  def index
    @scheduled_transactions = ScheduledTransaction.owned_by(current_user.id)
                                                 .order(next_occurrence: :asc)

    # Filter by status if parameter is present
    if params[:status].present?
      @scheduled_transactions = @scheduled_transactions.where(status: params[:status])
    end

    # Filter by type if parameter is present
    if params[:type].present?
      @scheduled_transactions = @scheduled_transactions.where(transaction_type: params[:type])
    end
  end

  def show
  end

  def new
    @scheduled_transaction = ScheduledTransaction.new
    @scheduled_transaction.transaction_type = params[:type] if params[:type].present?
    @scheduled_transaction.next_occurrence = Date.current + 1.day
    @payment_methods = current_user.payment_methods.active_methods.verified_methods

    # Load recent recipients for transfers
    if @scheduled_transaction.transaction_type == "transfer"
      @recent_recipients = Transaction.successful
                                     .where(transaction_type: :transfer, source_wallet_id: @wallet.id)
                                     .includes(destination_wallet: :user)
                                     .order(created_at: :desc)
                                     .limit(5)
                                     .map { |t| t.destination_wallet.user }
                                     .uniq
    end
  end

  def create
    @scheduled_transaction = ScheduledTransaction.new(scheduled_transaction_params)
    @scheduled_transaction.source_wallet = @wallet

    # Set destination wallet for transfers
    if @scheduled_transaction.transaction_type == "transfer" && params[:recipient].present?
      recipient = User.find_by("phone = ? OR username = ? OR email = ?",
                            params[:recipient], params[:recipient], params[:recipient])

      if recipient
        @scheduled_transaction.destination_wallet = recipient.wallet
      else
        flash.now[:error] = "Recipient not found"
        render :new
        return
      end
    end

    # Validate the amount against wallet balance for withdrawal and transfer
    if [ "withdrawal", "transfer" ].include?(@scheduled_transaction.transaction_type) &&
       @scheduled_transaction.amount > @wallet.balance
      flash.now[:error] = "Amount exceeds your current balance"
      render :new
      return
    end

    if @scheduled_transaction.save
      flash[:success] = "Scheduled transaction created successfully"
      redirect_to scheduled_transactions_path
    else
      flash.now[:error] = "Failed to create scheduled transaction: #{@scheduled_transaction.errors.full_messages.join(', ')}"
      @payment_methods = current_user.payment_methods.active_methods.verified_methods
      render :new
    end
  end

  def edit
    @payment_methods = current_user.payment_methods.active_methods.verified_methods
  end

  def update
    if @scheduled_transaction.update(scheduled_transaction_params)
      flash[:success] = "Scheduled transaction updated successfully"
      redirect_to scheduled_transaction_path(@scheduled_transaction)
    else
      flash.now[:error] = "Failed to update scheduled transaction: #{@scheduled_transaction.errors.full_messages.join(', ')}"
      @payment_methods = current_user.payment_methods.active_methods.verified_methods
      render :edit
    end
  end

  def destroy
    if @scheduled_transaction.destroy
      flash[:success] = "Scheduled transaction cancelled"
      redirect_to scheduled_transactions_path
    else
      flash[:error] = "Failed to cancel scheduled transaction"
      redirect_to scheduled_transaction_path(@scheduled_transaction)
    end
  end

  def pause
    if @scheduled_transaction.active?
      @scheduled_transaction.update(status: :paused)
      flash[:success] = "Scheduled transaction paused"
    else
      flash[:error] = "This scheduled transaction cannot be paused"
    end
    redirect_to scheduled_transaction_path(@scheduled_transaction)
  end

  def resume
    if @scheduled_transaction.paused?
      @scheduled_transaction.update(status: :active)
      flash[:success] = "Scheduled transaction resumed"
    else
      flash[:error] = "This scheduled transaction cannot be resumed"
    end
    redirect_to scheduled_transaction_path(@scheduled_transaction)
  end

  def execute
    if @scheduled_transaction.execute_transaction
      flash[:success] = "Scheduled transaction executed successfully"
    else
      flash[:error] = "Failed to execute the scheduled transaction"
    end
    redirect_to scheduled_transaction_path(@scheduled_transaction)
  end

  private

  def set_wallet
    @wallet = current_user.wallet

    # Create wallet if not exists
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

  def set_scheduled_transaction
    @scheduled_transaction = ScheduledTransaction.find(params[:id])
  end

  def ensure_ownership
    unless @scheduled_transaction.source_wallet.user_id == current_user.id
      flash[:error] = "You don't have permission to access this scheduled transaction"
      redirect_to scheduled_transactions_path
    end
  end

  def scheduled_transaction_params
    params.require(:scheduled_transaction).permit(
      :transaction_type, :amount, :frequency, :next_occurrence,
      :occurrences_limit, :description, :payment_method,
      :payment_provider, :payment_destination
    )
  end
end
