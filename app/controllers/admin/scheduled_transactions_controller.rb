module Admin
  class ScheduledTransactionsController < BaseController
    before_action :set_scheduled_transaction, only: [:show, :edit, :update, :destroy, :execute, :pause, :resume]

    def index
      @scheduled_transactions = ScheduledTransaction.all.order(next_occurrence: :asc)

      # Filter by status if provided
      if params[:status].present?
        @scheduled_transactions = @scheduled_transactions.where(status: params[:status])
      end

      # Filter by transaction type if provided
      if params[:transaction_type].present?
        @scheduled_transactions = @scheduled_transactions.where(transaction_type: params[:transaction_type])
      end

      # Filter by user if provided
      if params[:user_id].present?
        @scheduled_transactions = @scheduled_transactions.where(user_id: params[:user_id])
      end

      # Filter by search term if provided
      if params[:search].present?
        @scheduled_transactions = @scheduled_transactions.where("title LIKE ? OR description LIKE ?",
                                                             "%#{params[:search]}%",
                                                             "%#{params[:search]}%")
      end

      # Paginate results
      @pagy, @scheduled_transactions = pagy(@scheduled_transactions, items: 10)
    end

    def show
      # Load transaction history
      # First try to get transactions through the association
      if @scheduled_transaction.respond_to?(:transactions)
        @transaction_history = @scheduled_transaction.transactions.order(created_at: :desc)
      else
        # Fallback: Find transactions that have this scheduled transaction's ID in their metadata
        @transaction_history = Transaction.where("metadata->>'scheduled_transaction_id' = ?", @scheduled_transaction.id.to_s)
                                        .order(created_at: :desc)
      end
    end

    def new
      @scheduled_transaction = ScheduledTransaction.new
    end

    def create
      @scheduled_transaction = ScheduledTransaction.new(scheduled_transaction_params)

      if @scheduled_transaction.save
        redirect_to admin_scheduled_transaction_path(@scheduled_transaction), notice: "Scheduled transaction was successfully created."
      else
        render :new
      end
    end

    def edit
    end

    def update
      if @scheduled_transaction.update(scheduled_transaction_params)
        redirect_to admin_scheduled_transaction_path(@scheduled_transaction), notice: "Scheduled transaction was successfully updated."
      else
        render :edit
      end
    end

    def destroy
      if @scheduled_transaction.destroy
        redirect_to admin_scheduled_transactions_path, notice: "Scheduled transaction was successfully deleted."
      else
        redirect_to admin_scheduled_transaction_path(@scheduled_transaction), alert: "Failed to delete scheduled transaction."
      end
    end

    def execute
      result = @scheduled_transaction.execute_now!

      if result
        redirect_to admin_scheduled_transaction_path(@scheduled_transaction), notice: "Scheduled transaction was successfully executed."
      else
        redirect_to admin_scheduled_transaction_path(@scheduled_transaction), alert: "Failed to execute scheduled transaction."
      end
    end

    def pause
      if @scheduled_transaction.update(status: :paused)
        redirect_to admin_scheduled_transaction_path(@scheduled_transaction), notice: "Scheduled transaction has been paused."
      else
        redirect_to admin_scheduled_transaction_path(@scheduled_transaction), alert: "Failed to pause scheduled transaction."
      end
    end

    def resume
      if @scheduled_transaction.update(status: :active)
        redirect_to admin_scheduled_transaction_path(@scheduled_transaction), notice: "Scheduled transaction has been resumed."
      else
        redirect_to admin_scheduled_transaction_path(@scheduled_transaction), alert: "Failed to resume scheduled transaction."
      end
    end

    private

    def set_scheduled_transaction
      @scheduled_transaction = ScheduledTransaction.find_by(id: params[:id])

      unless @scheduled_transaction
        flash[:alert] = "Scheduled transaction not found"
        redirect_to admin_scheduled_transactions_path
      end
    end

    def scheduled_transaction_params
      params.require(:scheduled_transaction).permit(
        :user_id, :title, :description, :amount, :currency,
        :transaction_type, :frequency, :start_date, :end_date,
        :next_occurrence, :status, :source_wallet_id, :destination_wallet_id,
        :recipient_id, :recipient_type, :payment_method_id, :day_of_month,
        :day_of_week, :metadata
      )
    end
  end
end
