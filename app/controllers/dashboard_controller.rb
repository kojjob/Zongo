class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :set_wallet

  def index
    # Get recent transactions
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

    # Get total transaction count
    @transaction_count = Transaction.where("source_wallet_id = ? OR destination_wallet_id = ?", @wallet.id, @wallet.id).count

    # Get payment methods
    @payment_methods = current_user.payment_methods.order(default: :desc) rescue []

    # Get scheduled transactions/bills if that feature exists
    begin
      if ScheduledTransaction.table_exists?
        # Get all scheduled transactions
        @scheduled_transactions = current_user.scheduled_transactions.where("next_occurrence >= ?", Date.today).order(next_occurrence: :asc)

        # Get upcoming bills for the next 30 days
        @upcoming_bills = current_user.scheduled_transactions
                                     .where(status: :active)
                                     .where("next_occurrence <= ?", 30.days.from_now)
                                     .order(next_occurrence: :asc)
                                     .limit(5)

        # Calculate stats for upcoming bills widget
        @bills_due_today = current_user.scheduled_transactions
                                      .where(status: :active)
                                      .where("next_occurrence <= ?", Date.today.end_of_day)
                                      .count

        @bills_due_this_week = current_user.scheduled_transactions
                                          .where(status: :active)
                                          .where("next_occurrence <= ?", 7.days.from_now.end_of_day)
                                          .count

        @total_upcoming_amount = current_user.scheduled_transactions
                                            .where(status: :active)
                                            .where("next_occurrence <= ?", 30.days.from_now)
                                            .sum(:amount)
      else
        @scheduled_transactions = []
        @upcoming_bills = []
        @bills_due_today = 0
        @bills_due_this_week = 0
        @total_upcoming_amount = 0
      end
    rescue => e
      Rails.logger.error("Error getting scheduled transactions: #{e.message}")
      @scheduled_transactions = []
      @upcoming_bills = []
      @bills_due_today = 0
      @bills_due_this_week = 0
      @total_upcoming_amount = 0
    end
  end

  def refresh_balance
    respond_to do |format|
      format.json { render json: { balance: @wallet.balance, formatted_balance: @wallet.formatted_balance } }
    end
  end

  def refresh_transactions
    @recent_transactions = @wallet.recent_transactions(5)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to dashboard_path }
    end
  end

  def transaction_details
    @transaction = Transaction.find_by(id: params[:id])

    unless @transaction && (@transaction.source_wallet_id == @wallet.id || @transaction.destination_wallet_id == @wallet.id)
      respond_to do |format|
        format.json { render json: { error: "Transaction not found" }, status: :not_found }
        format.html { redirect_to dashboard_path, alert: "Transaction not found" }
      end
      return
    end

    respond_to do |format|
      format.json {
        render json: {
          html: render_to_string(
            partial: 'transactions/transaction_details_modal',
            locals: { transaction: @transaction },
            layout: false
          )
        }
      }
      format.html { redirect_to transaction_path(@transaction) }
    end
  end

  def customize_shortcuts
    respond_to do |format|
      format.json {
        render json: {
          html: render_to_string(
            partial: 'dashboard/customize_shortcuts_modal',
            layout: false
          )
        }
      }
      format.html { redirect_to dashboard_path }
    end
  end

  private

  # Set wallet from user association
  def set_wallet
    @wallet = current_user.wallet

    # If user doesn't have a wallet yet, create one (copied from your WalletsController)
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
end
