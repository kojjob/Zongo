class StatementsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_wallet

  def new
    # Default to last month if no dates specified
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.current.beginning_of_month - 1.month
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current.end_of_month - 1.month
  end

  def generate
    @start_date = params[:start_date].present? ? Date.parse(params[:start_date]) : Date.current.beginning_of_month - 1.month
    @end_date = params[:end_date].present? ? Date.parse(params[:end_date]) : Date.current.end_of_month - 1.month

    # Validate date range
    if @end_date < @start_date
      flash.now[:error] = "End date cannot be before start date"
      render :new
      return
    end

    if @end_date > Date.current
      flash.now[:error] = "End date cannot be in the future"
      render :new
      return
    end

    # Get transactions for the period
    @transactions = Transaction.where("(source_wallet_id = ? OR destination_wallet_id = ?) AND created_at BETWEEN ? AND ?",
                               @wallet.id, @wallet.id, @start_date.beginning_of_day, @end_date.end_of_day)
                              .order(created_at: :asc)

    # Calculate summary data
    @opening_balance = calculate_opening_balance(@start_date)
    @closing_balance = calculate_closing_balance(@end_date)
    @total_inflow = calculate_total_inflow(@start_date, @end_date)
    @total_outflow = calculate_total_outflow(@start_date, @end_date)

    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "statement_#{@start_date.strftime('%Y%m%d')}_#{@end_date.strftime('%Y%m%d')}",
               template: "statements/generate",
               layout: "pdf",
               disposition: "attachment",
               page_size: "A4",
               margin: { top: 20, bottom: 20, left: 20, right: 20 },
               footer: {
                 center: "Page [page] of [topage]",
                 font_size: 9,
                 spacing: 5
               }
      end
    end
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

  def calculate_opening_balance(start_date)
    # Sum all transactions before the start date to get opening balance
    balance = 0

    # Add inflows
    inflow = Transaction.successful
                       .where(destination_wallet_id: @wallet.id)
                       .where("created_at < ?", start_date.beginning_of_day)
                       .sum(:amount)
    balance += inflow

    # Subtract outflows
    outflow = Transaction.successful
                       .where(source_wallet_id: @wallet.id)
                       .where("created_at < ?", start_date.beginning_of_day)
                       .sum(:amount)
    balance -= outflow

    balance
  end

  def calculate_closing_balance(end_date)
    # Sum all transactions up to the end date to get closing balance
    balance = 0

    # Add inflows
    inflow = Transaction.successful
                       .where(destination_wallet_id: @wallet.id)
                       .where("created_at <= ?", end_date.end_of_day)
                       .sum(:amount)
    balance += inflow

    # Subtract outflows
    outflow = Transaction.successful
                       .where(source_wallet_id: @wallet.id)
                       .where("created_at <= ?", end_date.end_of_day)
                       .sum(:amount)
    balance -= outflow

    balance
  end

  def calculate_total_inflow(start_date, end_date)
    Transaction.successful
             .where(destination_wallet_id: @wallet.id)
             .where("created_at BETWEEN ? AND ?", start_date.beginning_of_day, end_date.end_of_day)
             .sum(:amount)
  end

  def calculate_total_outflow(start_date, end_date)
    Transaction.successful
             .where(source_wallet_id: @wallet.id)
             .where("created_at BETWEEN ? AND ?", start_date.beginning_of_day, end_date.end_of_day)
             .sum(:amount)
  end
end
