class LoanStatusUpdateJob < ApplicationJob
  queue_as :default

  # Number of days after which a loan is considered defaulted
  DEFAULT_DAYS = 30

  def perform
    # Find active loans that are significantly overdue
    update_defaulted_loans
  end
  
  private
  
  def update_defaulted_loans
    # Find active loans that are overdue by more than DEFAULT_DAYS days
    defaulted_loans = Loan.where(status: :active)
                          .where("due_date < ?", DEFAULT_DAYS.days.ago.to_date)
    
    defaulted_loans.find_each do |loan|
      # Mark loan as defaulted
      loan.update(
        status: :defaulted,
        defaulted_at: Time.current
      )
      
      # Notify user about loan default
      UserNotificationService.new.notify_loan_defaulted(loan) if defined?(UserNotificationService)
      
      # Notify admin about loan default
      AdminNotificationService.new.notify_loan_defaulted(loan) if defined?(AdminNotificationService)
      
      # Log the status change
      Rails.logger.info "Loan #{loan.reference_number} marked as defaulted, #{(Date.today - loan.due_date.to_date).to_i} days overdue"
    end
  end
end
