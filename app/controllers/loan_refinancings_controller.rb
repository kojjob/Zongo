class LoanRefinancingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_loan, only: [:new, :create, :eligibility, :calculate_savings]
  before_action :set_refinancing, only: [:show, :cancel]

  def index
    @refinancings = current_user.loan_refinancings.recent.includes(:original_loan, :new_loan)
    @eligible_loans = LoanRefinancingService.new(current_user).eligible_loans
  end

  def show
    @original_loan = @refinancing.original_loan
    @new_loan = @refinancing.new_loan
  end

  def new
    # Check if the loan is eligible for refinancing
    @service = LoanRefinancingService.new(current_user)

    unless @service.eligible_for_refinancing?(@loan)
      redirect_to loans_path, alert: "This loan is not eligible for refinancing."
      return
    end

    # Calculate potential savings
    @savings = @service.calculate_savings(@loan)

    # Create a new refinancing object
    @refinancing = LoanRefinancing.new(
      user: current_user,
      original_loan: @loan,
      requested_amount: @loan.current_balance,
      original_rate: @loan.interest_rate,
      requested_rate: @savings[:new_rate],
      term_days: calculate_term_days(@loan)
    )
  end

  def create
    @service = LoanRefinancingService.new(current_user)

    unless @service.eligible_for_refinancing?(@loan)
      redirect_to loans_path, alert: "This loan is not eligible for refinancing."
      return
    end

    # Create the refinancing application
    @refinancing = @service.create_refinancing_application(@loan, refinancing_params)

    if @refinancing.persisted?
      # Create a notification for the user
      current_user.create_notification(
        title: "Refinancing Application Submitted",
        content: "Your application to refinance loan ##{@loan.reference_number} has been submitted and is pending approval.",
        notification_type: "loan",
        source_type: "LoanRefinancing",
        source_id: @refinancing.id
      )

      # Create a notification for admins
      AdminNotificationService.new.notify_admins(
        title: "New Loan Refinancing Application",
        content: "User #{current_user.display_name} has submitted a refinancing application for loan ##{@loan.reference_number}.",
        notification_type: "loan",
        source_type: "LoanRefinancing",
        source_id: @refinancing.id
      )

      redirect_to loan_refinancing_path(@refinancing), notice: "Your refinancing application has been submitted successfully."
    else
      @savings = @service.calculate_savings(@loan)
      render :new, status: :unprocessable_entity
    end
  end

  def eligibility
    @service = LoanRefinancingService.new(current_user)
    eligible = @service.eligible_for_refinancing?(@loan)

    respond_to do |format|
      format.json { render json: { eligible: eligible } }
    end
  end

  def calculate_savings
    @service = LoanRefinancingService.new(current_user)
    @savings = @service.calculate_savings(@loan)

    respond_to do |format|
      format.json { render json: @savings }
    end
  end

  def cancel
    if @refinancing.pending?
      @refinancing.update(status: :cancelled, cancelled_at: Time.current)
      redirect_to loan_refinancings_path, notice: "Your refinancing application has been cancelled."
    else
      redirect_to loan_refinancing_path(@refinancing), alert: "This refinancing application cannot be cancelled."
    end
  end

  private

  def set_loan
    @loan = current_user.loans.find(params[:loan_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to loans_path, alert: "Loan not found."
  end

  def set_refinancing
    @refinancing = current_user.loan_refinancings.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to loan_refinancings_path, alert: "Refinancing application not found."
  end

  def refinancing_params
    params.require(:loan_refinancing).permit(:reason, :term_days)
  end

  def calculate_term_days(loan)
    # By default, use the remaining days from the original loan
    if loan.due_date.present?
      begin
        remaining_days = (loan.due_date.to_date - Date.today).to_i
        # Ensure at least 30 days
        return [remaining_days, 30].max
      rescue
        # If there's any error calculating the remaining days, default to 90 days
        return 90
      end
    else
      # If no due date, default to 90 days
      return 90
    end
  end
end
