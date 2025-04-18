module Admin
  class LoansController < Admin::BaseController
    before_action :set_loan, only: [ :show, :approve, :reject, :disburse ]

    def index
      @loans = Loan.all.order(created_at: :desc)
      @loans = @loans.where(status: params[:status]) if params[:status].present?

      # Add pagination if available
      @loans = @loans.page(params[:page]).per(20) if @loans.respond_to?(:page)
    end

    def show
      # Load loan repayments
      @repayments = @loan.loan_repayments.order(created_at: :desc)

      # Get user credit score data
      @credit_score_data = @loan.credit_score_data
    end

    def approve
      @loan.interest_rate = params[:interest_rate] if params[:interest_rate].present?
      @loan.processing_fee = params[:processing_fee] if params[:processing_fee].present?
      @loan.term_days = params[:term_days] if params[:term_days].present?
      @loan.due_date = Time.current + @loan.term_days.days
      @loan.calculate_amount_due

      if @loan.update(status: :approved)
        # Notify user about approval
        UserNotificationService.new.notify_loan_approved(@loan)
        redirect_to admin_loan_path(@loan), notice: "Loan approved successfully"
      else
        redirect_to admin_loan_path(@loan), alert: "Failed to approve loan"
      end
    end

    def reject
      if @loan.update(status: :rejected, rejection_reason: params[:rejection_reason])
        # Notify user about rejection
        UserNotificationService.new.notify_loan_rejected(@loan)
        redirect_to admin_loan_path(@loan), notice: "Loan rejected successfully"
      else
        redirect_to admin_loan_path(@loan), alert: "Failed to reject loan"
      end
    end

    def disburse
      disbursal_service = LoanDisbursalService.new(@loan)
      result = disbursal_service.disburse

      if result[:success]
        redirect_to admin_loan_path(@loan), notice: "Loan disbursed successfully"
      else
        redirect_to admin_loan_path(@loan), alert: result[:message]
      end
    end

    private

    def set_loan
      @loan = Loan.find(params[:id])
    end
  end
end
