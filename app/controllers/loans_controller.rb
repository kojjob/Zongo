class LoansController < ApplicationController
  before_action :authenticate_user!
  before_action :set_loan, only: [ :show, :repay, :schedule, :details ]

  def index
    @loans = current_user.loans.order(created_at: :desc)
  end

  def show
  end

  def new
    @loan = Loan.new
    @loan_types = Loan.loan_types.keys.map { |type| [ type.titleize, type ] }
    @max_amount = current_user.loan_limit
  end

  def create
    @loan = current_user.loans.new(loan_params)
    @loan.wallet = current_user.primary_wallet
    @loan.status = :pending

    # Set default values based on loan type
    set_loan_defaults

    # Calculate credit score and store it
    credit_score_service = CreditScoreService.new(current_user)
    @loan.credit_score_data = credit_score_service.calculate

    if @loan.save
      # Notify admins about new loan application
      AdminNotificationService.new.notify_new_loan_application(@loan)

      redirect_to @loan, notice: "Loan application submitted successfully."
    else
      @loan_types = Loan.loan_types.keys.map { |type| [ type.titleize, type ] }
      @max_amount = current_user.loan_limit
      render :new
    end
  end

  def eligibility
    @eligible = current_user.eligible_for_loan?
    @credit_score = current_user.current_credit_score
    @loan_limit = current_user.loan_limit
    @reasons = []

    unless current_user.has_verified_identity?
      @reasons << "Identity verification required"
    end

    if current_user.has_active_defaulted_loan?
      @reasons << "You have an active or defaulted loan"
    end

    if @credit_score.nil? || @credit_score.score < 500
      @reasons << "Credit score below minimum requirement"
    end
  end

  def types
    @loan_types = [
      {
        type: "microloan",
        name: "Microloan",
        description: "Small, short-term loans for immediate needs",
        min_amount: 50,
        max_amount: 500,
        term_range: "7-30 days",
        interest_rate: "3-5% flat",
        requirements: [ "Valid ID", "Active account for 30+ days" ]
      },
      {
        type: "emergency",
        name: "Emergency Loan",
        description: "Quick access loans for urgent situations",
        min_amount: 100,
        max_amount: 1000,
        term_range: "1-14 days",
        interest_rate: "5-8% flat",
        requirements: [ "Valid ID", "Active account for 60+ days" ]
      },
      {
        type: "installment",
        name: "Installment Loan",
        description: "Longer-term loans with scheduled repayments",
        min_amount: 500,
        max_amount: 5000,
        term_range: "30-180 days",
        interest_rate: "10-15% p.a.",
        requirements: [ "Valid ID", "Active account for 90+ days", "Credit score 600+" ]
      },
      {
        type: "business",
        name: "Business Loan",
        description: "Loans for small business owners",
        min_amount: 1000,
        max_amount: 10000,
        term_range: "90-365 days",
        interest_rate: "12-18% p.a.",
        requirements: [ "Business registration", "Active account for 180+ days", "Credit score 650+" ]
      },
      {
        type: "agricultural",
        name: "Agricultural Loan",
        description: "Specialized loans for farmers",
        min_amount: 500,
        max_amount: 5000,
        term_range: "90-365 days",
        interest_rate: "8-12% p.a.",
        requirements: [ "Proof of farming activity", "Active account for 90+ days", "Credit score 550+" ]
      },
      {
        type: "salary_advance",
        name: "Salary Advance",
        description: "Short-term loans based on your salary",
        min_amount: 100,
        max_amount: 2000,
        term_range: "1-30 days",
        interest_rate: "2-4% flat",
        requirements: [ "Proof of employment", "Salary deposits for 2+ months", "Credit score 500+" ]
      }
    ]
  end

  def repay
    amount = params[:amount].to_f

    if amount <= 0 || amount > @loan.current_balance
      return redirect_to @loan, alert: "Invalid repayment amount"
    end

    repayment_service = LoanRepaymentService.new(@loan)
    result = repayment_service.process_repayment(amount)

    if result[:success]
      redirect_to @loan, notice: "Loan repayment successful"
    else
      redirect_to @loan, alert: result[:message]
    end
  end

  def schedule
    @schedule = @loan.repayment_schedule

    # If the loan is not active or approved, generate a sample schedule
    if @schedule.blank? && (@loan.pending? || @loan.approved?)
      # Generate a sample schedule for display purposes
      @schedule = generate_sample_schedule(@loan)
    end
  end

  def details
    # Load credit score data if available
    if @loan.credit_score_data.blank?
      credit_score_service = CreditScoreService.new(@loan.user)
      @loan.credit_score_data = credit_score_service.calculate
      @loan.save
    end
  end

  private

  def set_loan
    @loan = current_user.loans.find_by(id: params[:id])

    unless @loan
      redirect_to loans_path, alert: "Loan not found."
      return
    end
  end

  def loan_params
    params.require(:loan).permit(:loan_type, :amount, :term_days)
  end

  def set_loan_defaults
    # Set default values based on loan type
    case @loan.loan_type
    when "microloan"
      @loan.interest_rate = 5.0
      @loan.processing_fee = @loan.amount * 0.01
      @loan.term_days = 30 if @loan.term_days.blank?
    when "emergency"
      @loan.interest_rate = 8.0
      @loan.processing_fee = @loan.amount * 0.02
      @loan.term_days = 14 if @loan.term_days.blank?
    when "installment"
      @loan.interest_rate = 15.0
      @loan.processing_fee = @loan.amount * 0.015
      @loan.term_days = 90 if @loan.term_days.blank?
    when "business"
      @loan.interest_rate = 18.0
      @loan.processing_fee = @loan.amount * 0.02
      @loan.term_days = 180 if @loan.term_days.blank?
    when "agricultural"
      @loan.interest_rate = 12.0
      @loan.processing_fee = @loan.amount * 0.01
      @loan.term_days = 180 if @loan.term_days.blank?
    when "salary_advance"
      @loan.interest_rate = 4.0
      @loan.processing_fee = @loan.amount * 0.005
      @loan.term_days = 30 if @loan.term_days.blank?
    end

    # Set due date
    @loan.due_date = Time.current + @loan.term_days.days
  end

  def generate_sample_schedule(loan)
    # This is a sample schedule for display purposes only
    # The actual schedule will be generated when the loan is approved

    schedule = []

    # For installment loans, generate multiple installments
    if ["installment", "business", "agricultural"].include?(loan.loan_type)
      # Calculate number of installments (approximately monthly)
      num_installments = [loan.term_days / 30, 1].max

      # Calculate installment amount
      total_amount = loan.amount + (loan.amount * loan.interest_rate / 100 * loan.term_days / 365) + loan.processing_fee
      installment_amount = (total_amount / num_installments).round(2)

      # Generate installments
      num_installments.times do |i|
        due_date = Time.current + ((i + 1) * (loan.term_days / num_installments)).days

        schedule << {
          installment_number: i + 1,
          due_date: due_date,
          amount: installment_amount,
          status: "upcoming"
        }
      end
    else
      # For non-installment loans, generate a single payment
      total_amount = loan.amount + (loan.amount * loan.interest_rate / 100 * loan.term_days / 365) + loan.processing_fee

      schedule << {
        installment_number: 1,
        due_date: loan.due_date,
        amount: total_amount,
        status: "upcoming"
      }
    end

    schedule
  end
end
