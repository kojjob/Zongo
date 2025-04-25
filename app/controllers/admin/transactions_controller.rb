module Admin
  class TransactionsController < BaseController
    before_action :set_transaction, only: [:show, :edit, :update, :destroy, :approve, :reject, :reverse]

    def index
      @transactions = Transaction.all.order(created_at: :desc)

      # Filter by status if provided
      if params[:status].present?
        @transactions = @transactions.where(status: params[:status])
      end

      # Filter by transaction type if provided
      if params[:transaction_type].present?
        @transactions = @transactions.where(transaction_type: params[:transaction_type])
      end

      # Filter by user if provided
      if params[:user_id].present?
        user = User.find(params[:user_id])
        @transactions = @transactions.by_user(user.id)
      end

      # Filter by date range if provided
      if params[:start_date].present? && params[:end_date].present?
        start_date = Date.parse(params[:start_date])
        end_date = Date.parse(params[:end_date])
        @transactions = @transactions.by_date_range(start_date, end_date)
      end

      # Filter by search term if provided
      if params[:search].present?
        @transactions = @transactions.where("transaction_id LIKE ? OR description LIKE ?",
                                          "%#{params[:search]}%",
                                          "%#{params[:search]}%")
      end

      # Paginate results
      @pagy, @transactions = pagy(@transactions, items: 10)
    end

    def show
      # Load related security logs
      @security_logs = @transaction.security_logs.order(created_at: :desc)
    end

    def new
      @transaction = Transaction.new
    end

    def create
      # Determine transaction type and create accordingly
      case params[:transaction][:transaction_type]
      when "deposit"
        create_deposit
      when "withdrawal"
        create_withdrawal
      when "transfer"
        create_transfer
      when "payment"
        create_payment
      else
        @transaction = Transaction.new(transaction_params)
        if @transaction.save
          redirect_to admin_transaction_path(@transaction), notice: "Transaction was successfully created."
        else
          render :new
        end
      end
    end

    def edit
    end

    def update
      if @transaction.update(transaction_params)
        redirect_to admin_transaction_path(@transaction), notice: "Transaction was successfully updated."
      else
        render :edit
      end
    end

    def destroy
      if @transaction.destroy
        redirect_to admin_transactions_path, notice: "Transaction was successfully deleted."
      else
        redirect_to admin_transaction_path(@transaction), alert: "Failed to delete transaction."
      end
    end

    def approve
      if @transaction.status_pending? && @transaction.complete!
        redirect_to admin_transaction_path(@transaction), notice: "Transaction has been approved and completed."
      else
        redirect_to admin_transaction_path(@transaction), alert: "Failed to approve transaction."
      end
    end

    def reject
      if @transaction.fail!(reason: params[:reason])
        redirect_to admin_transaction_path(@transaction), notice: "Transaction has been rejected."
      else
        redirect_to admin_transaction_path(@transaction), alert: "Failed to reject transaction."
      end
    end

    def reverse
      if @transaction.reverse!(reason: params[:reason])
        redirect_to admin_transaction_path(@transaction), notice: "Transaction has been reversed."
      else
        redirect_to admin_transaction_path(@transaction), alert: "Failed to reverse transaction."
      end
    end

    private

    def set_transaction
      # Try to find by transaction_id first, then by ID
      @transaction = Transaction.find_by(transaction_id: params[:id]) || Transaction.find(params[:id])
    end

    def transaction_params
      params.require(:transaction).permit(
        :transaction_type, :status, :amount, :fee, :currency,
        :source_wallet_id, :destination_wallet_id, :payment_method,
        :provider, :description, :metadata, :external_reference
      )
    end

    def create_deposit
      wallet = Wallet.find(params[:transaction][:destination_wallet_id])

      @transaction = Transaction.create_deposit(
        wallet: wallet,
        amount: params[:transaction][:amount].to_f,
        payment_method: params[:transaction][:payment_method].to_sym,
        provider: params[:transaction][:provider],
        metadata: { admin_created: true, admin_id: current_user.id }
      )

      if @transaction.persisted?
        redirect_to admin_transaction_path(@transaction), notice: "Deposit transaction was successfully created."
      else
        render :new
      end
    end

    def create_withdrawal
      wallet = Wallet.find(params[:transaction][:source_wallet_id])

      @transaction = Transaction.create_withdrawal(
        wallet: wallet,
        amount: params[:transaction][:amount].to_f,
        payment_method: params[:transaction][:payment_method].to_sym,
        provider: params[:transaction][:provider],
        metadata: { admin_created: true, admin_id: current_user.id }
      )

      if @transaction.persisted?
        redirect_to admin_transaction_path(@transaction), notice: "Withdrawal transaction was successfully created."
      else
        render :new
      end
    end

    def create_transfer
      source_wallet = Wallet.find(params[:transaction][:source_wallet_id])
      destination_wallet = Wallet.find(params[:transaction][:destination_wallet_id])

      @transaction = Transaction.create_transfer(
        source_wallet: source_wallet,
        destination_wallet: destination_wallet,
        amount: params[:transaction][:amount].to_f,
        description: params[:transaction][:description],
        metadata: { admin_created: true, admin_id: current_user.id }
      )

      if @transaction.persisted?
        redirect_to admin_transaction_path(@transaction), notice: "Transfer transaction was successfully created."
      else
        render :new
      end
    end

    def create_payment
      source_wallet = Wallet.find(params[:transaction][:source_wallet_id])
      destination_wallet = Wallet.find(params[:transaction][:destination_wallet_id])

      @transaction = Transaction.create_payment(
        source_wallet: source_wallet,
        destination_wallet: destination_wallet,
        amount: params[:transaction][:amount].to_f,
        description: params[:transaction][:description],
        metadata: { admin_created: true, admin_id: current_user.id }
      )

      if @transaction.persisted?
        redirect_to admin_transaction_path(@transaction), notice: "Payment transaction was successfully created."
      else
        render :new
      end
    end
  end
end
