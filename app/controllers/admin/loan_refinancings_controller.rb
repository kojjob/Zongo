module Admin
  class LoanRefinancingsController < AdminController
    before_action :set_refinancing, only: [:show, :approve, :reject]
    
    def index
      @refinancings = LoanRefinancing.includes(:user, :original_loan, :new_loan).order(created_at: :desc)
      
      # Filter by status if provided
      if params[:status].present? && LoanRefinancing.statuses.key?(params[:status])
        @refinancings = @refinancings.where(status: params[:status])
      end
      
      # Paginate results
      @refinancings = @refinancings.page(params[:page]).per(20)
    end
    
    def show
      @original_loan = @refinancing.original_loan
      @user = @refinancing.user
      
      # Get user's credit score
      @credit_score = @user.current_credit_score
      
      # Get user's other loans
      @other_loans = @user.loans.where.not(id: @original_loan.id).active
    end
    
    def approve
      service = LoanRefinancingService.new(@refinancing.user)
      
      if service.approve_refinancing(@refinancing)
        redirect_to admin_loan_refinancing_path(@refinancing), notice: "Refinancing application has been approved."
      else
        redirect_to admin_loan_refinancing_path(@refinancing), alert: "Failed to approve refinancing application."
      end
    end
    
    def reject
      service = LoanRefinancingService.new(@refinancing.user)
      
      if service.reject_refinancing(@refinancing, params[:rejection_reason])
        redirect_to admin_loan_refinancing_path(@refinancing), notice: "Refinancing application has been rejected."
      else
        redirect_to admin_loan_refinancing_path(@refinancing), alert: "Failed to reject refinancing application."
      end
    end
    
    private
    
    def set_refinancing
      @refinancing = LoanRefinancing.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_loan_refinancings_path, alert: "Refinancing application not found."
    end
  end
end
