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
    @transaction_count = Transaction.where('source_wallet_id = ? OR destination_wallet_id = ?', @wallet.id, @wallet.id).count
    
    # Get payment methods
    @payment_methods = current_user.payment_methods.order(default: :desc) rescue []
    
    # Get scheduled transactions/bills if that feature exists
    @scheduled_transactions = current_user.scheduled_transactions.where("next_date >= ?", Date.today).order(next_date: :asc) rescue []
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
        currency: 'GHS',
        daily_limit: 1000
      )
    end
  end
end