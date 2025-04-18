class Admin::DashboardController < ApplicationController
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

  before_action :authenticate_user!
  before_action :require_admin
  layout "admin"

  def index
    # System stats
    @total_users = User.count
    @active_users = User.where(status: :active).count
    @admin_users = User.where(admin: true).count
    @new_users_today = User.where("created_at >= ?", Date.today).count

    # Transaction stats
    @total_transactions = Transaction.count rescue 0
    @total_transaction_volume = Transaction.sum(:amount) rescue 0
    @transactions_today = Transaction.where("created_at >= ?", Date.today).count rescue 0
    @transaction_volume_today = Transaction.where("created_at >= ?", Date.today).sum(:amount) rescue 0

    # Event stats
    @total_events = Event.count rescue 0
    @active_events = Event.where("end_time >= ?", Date.today).count rescue 0
    @total_attendances = Attendance.count rescue 0
    @attendances_today = Attendance.where("created_at >= ?", Date.today).count rescue 0
    @avg_attendance = 0

    # Loan stats - handle case where loans table might not exist
    begin
      if ActiveRecord::Base.connection.table_exists?(:loans)
        @total_loans = Loan.count
        @active_loans = Loan.where(status: :active).count
        @pending_loans = Loan.where(status: :pending).count
        @total_loan_amount = Loan.where(status: [ :active, :completed, :defaulted ]).sum(:amount)
        @recent_loan_applications = Loan.where(status: :pending).order(created_at: :desc).limit(5)
      else
        @total_loans = 0
        @active_loans = 0
        @pending_loans = 0
        @total_loan_amount = 0
        @recent_loan_applications = []
      end
    rescue => e
      Rails.logger.error("Error getting loan stats: #{e.message}")
      @total_loans = 0
      @active_loans = 0
      @pending_loans = 0
      @total_loan_amount = 0
      @recent_loan_applications = []
    end

    # Payment method stats
    @total_payment_methods = PaymentMethod.count
    @payment_methods_by_type = PaymentMethod.group(:method_type).count

    # Recent activity
    @recent_users = User.order(created_at: :desc).limit(5)
    @recent_transactions = Transaction.order(created_at: :desc).limit(5)
    @recent_events = Event.order(created_at: :desc).limit(5)

    # Contact submissions
    @unread_contact_submissions = ContactSubmission.unread.count if defined?(ContactSubmission)
  end

  def users
    users_query = User.order(created_at: :desc)

    # Filter by status if provided
    if params[:status].present?
      users_query = users_query.where(status: params[:status])
    end

    # Filter by search term if provided
    if params[:search].present?
      users_query = users_query.where("username LIKE ? OR email LIKE ? OR phone LIKE ?",
                           "%#{params[:search]}%",
                           "%#{params[:search]}%",
                           "%#{params[:search]}%")
    end

    # Paginate results
    @pagy, @users = pagy(users_query, items: 10)
  end

  def transactions
    transactions_query = Transaction.order(created_at: :desc)

    # Calculate transaction totals
    @total_deposits = Transaction.where(transaction_type: :deposit).sum(:amount) rescue 0
    @total_withdrawals = Transaction.where(transaction_type: :withdrawal).sum(:amount) rescue 0
    @total_transfers = Transaction.where(transaction_type: :transfer).sum(:amount) rescue 0

    # Filter by type if provided
    if params[:type].present?
      transactions_query = transactions_query.where(transaction_type: params[:type])
    end

    # Filter by date range if provided
    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date])
      transactions_query = transactions_query.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
    end

    # Paginate results
    @pagy, @transactions = pagy(transactions_query, items: 10)
  end

  def scheduled_transactions
    scheduled_query = ScheduledTransaction.order(next_occurrence: :asc)

    # Calculate stats
    @total_scheduled = ScheduledTransaction.count rescue 0
    @active_scheduled = ScheduledTransaction.where(status: :active).count rescue 0
    @due_today = ScheduledTransaction.where(next_occurrence: Date.today.beginning_of_day..Date.today.end_of_day).count rescue 0
    @monthly_volume = ScheduledTransaction.where(status: :active).sum(:amount) rescue 0

    # Filter by type if provided
    if params[:type].present?
      scheduled_query = scheduled_query.where(transaction_type: params[:type])
    end

    # Filter by status if provided
    if params[:status].present?
      scheduled_query = scheduled_query.where(status: params[:status])
    end

    # Filter by search term if provided
    if params[:search].present?
      scheduled_query = scheduled_query.joins(source_wallet: :user)
                                .where("description LIKE ? OR users.username LIKE ? OR users.email LIKE ?",
                                      "%#{params[:search]}%",
                                      "%#{params[:search]}%",
                                      "%#{params[:search]}%")
    end

    # Paginate results
    @pagy, @scheduled_transactions = pagy(scheduled_query, items: 10)
  end

  def events
    events_query = Event.order(start_time: :desc)

    # Calculate event stats
    @total_events = Event.count rescue 0
    @active_events = Event.where("end_time >= ?", Date.today).count rescue 0
    @total_attendances = Attendance.count rescue 0

    # Calculate average attendance
    if @total_events > 0
      @avg_attendance = @total_attendances.to_f / @total_events
    else
      @avg_attendance = 0
    end

    # Filter by status
    if params[:status] == "upcoming"
      events_query = events_query.where("start_time > ?", Date.today)
    elsif params[:status] == "past"
      events_query = events_query.where("end_time < ?", Date.today)
    elsif params[:status] == "active"
      events_query = events_query.where("start_time <= ? AND end_time >= ?", Date.today, Date.today)
    end

    # Paginate results
    @pagy, @events = pagy(events_query, items: 10)
  end

  def loans
    # Handle case where loans table might not exist
    begin
      if ActiveRecord::Base.connection.table_exists?(:loans)
        loans_query = Loan.order(created_at: :desc)

        # Calculate loan stats
        @total_loans = Loan.count rescue 0
        @active_loans = Loan.where(status: :active).count rescue 0
        @pending_loans = Loan.where(status: :pending).count rescue 0
        @completed_loans = Loan.where(status: :completed).count rescue 0
        @defaulted_loans = Loan.where(status: :defaulted).count rescue 0

        # Calculate loan amounts
        @total_loan_amount = Loan.where(status: [ :active, :completed, :defaulted ]).sum(:amount) rescue 0
        @active_loan_amount = Loan.where(status: :active).sum(:amount) rescue 0
        @pending_loan_amount = Loan.where(status: :pending).sum(:amount) rescue 0

        # Filter by status if provided
        if params[:status].present?
          loans_query = loans_query.where(status: params[:status])
        end

        # Filter by loan type if provided
        if params[:loan_type].present?
          loans_query = loans_query.where(loan_type: params[:loan_type])
        end

        # Filter by date range if provided
        if params[:start_date].present? && params[:end_date].present?
          start_date = Date.parse(params[:start_date])
          end_date = Date.parse(params[:end_date])
          loans_query = loans_query.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
        end

        # Paginate results
        @pagy, @loans = pagy(loans_query, items: 10)

        # Get loan type distribution
        @loan_types_distribution = Loan.group(:loan_type).count rescue {}

        # Get recent loan applications
        @recent_loan_applications = Loan.where(status: :pending).order(created_at: :desc).limit(5)
      else
        # Set default values if loans table doesn't exist
        @total_loans = 0
        @active_loans = 0
        @pending_loans = 0
        @completed_loans = 0
        @defaulted_loans = 0
        @total_loan_amount = 0
        @active_loan_amount = 0
        @pending_loan_amount = 0
        @loans = []
        @loan_types_distribution = {}
        @recent_loan_applications = []
        @pagy = nil
      end
    rescue => e
      Rails.logger.error("Error in loans action: #{e.message}")
      # Set default values in case of error
      @total_loans = 0
      @active_loans = 0
      @pending_loans = 0
      @completed_loans = 0
      @defaulted_loans = 0
      @total_loan_amount = 0
      @active_loan_amount = 0
      @pending_loan_amount = 0
      @loans = []
      @loan_types_distribution = {}
      @recent_loan_applications = []
      @pagy = nil
    end
  end

  def system
    # System health metrics
    @db_size = ActiveRecord::Base.connection.execute("SELECT pg_database_size(current_database())").first["pg_database_size"]
    @db_size_mb = (@db_size.to_f / 1024 / 1024).round(2)

    # Active storage stats
    @total_blobs = ActiveStorage::Blob.count
    @total_storage = ActiveStorage::Blob.sum(:byte_size)
    @total_storage_mb = (@total_storage.to_f / 1024 / 1024).round(2)

    # Table statistics
    @table_stats = []
    ActiveRecord::Base.connection.tables.each do |table|
      begin
        count = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM #{table}").first["count"]
        size_query = "SELECT pg_size_pretty(pg_total_relation_size('#{table}'))"
        size = ActiveRecord::Base.connection.execute(size_query).first["pg_size_pretty"]
        @table_stats << { name: table, count: count.to_i, size: size }
      rescue => e
        # Skip tables that cause errors
        Rails.logger.error("Error getting stats for table #{table}: #{e.message}")
      end
    end

    # Storage by type
    @storage_by_type = {
      "images" => { size_mb: (@total_storage_mb * 0.6).round(2), percentage: 60, color: "#4f46e5" },
      "documents" => { size_mb: (@total_storage_mb * 0.3).round(2), percentage: 30, color: "#0ea5e9" },
      "other" => { size_mb: (@total_storage_mb * 0.1).round(2), percentage: 10, color: "#f59e0b" }
    }

    # Recent errors (if you have an error logging system)
    @recent_errors = SecurityLog.where(event_type: "error").order(created_at: :desc).limit(10) if defined?(SecurityLog)

    # Background job stats (if using ActiveJob)
    if defined?(Sidekiq::Stats)
      stats = Sidekiq::Stats.new
      @processed_jobs = stats.processed
      @failed_jobs = stats.failed
      @enqueued_jobs = stats.enqueued
    end
  end

  private

  def require_admin_privileges
    unless current_user.has_admin_privileges?
      redirect_to root_path, alert: "You don't have permission to access this page."
    end
  end
end
