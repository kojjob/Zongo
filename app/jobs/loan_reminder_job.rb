class LoanReminderJob < ApplicationJob
  queue_as :default

  def perform
    # Find active loans with upcoming payments
    check_upcoming_payments
    
    # Find overdue loans
    check_overdue_loans
  end
  
  private
  
  def check_upcoming_payments
    # Find active loans with payments due in the next 3 days
    upcoming_loans = Loan.where(status: :active)
                         .where("due_date BETWEEN ? AND ?", Date.today, 3.days.from_now.to_date)
    
    upcoming_loans.find_each do |loan|
      days_remaining = (loan.due_date.to_date - Date.today).to_i
      
      # Send notification to user
      UserNotificationService.new.notify_loan_due_soon(loan, days_remaining)
      
      # Log the reminder
      Rails.logger.info "Sent payment reminder for loan #{loan.reference_number}, due in #{days_remaining} days"
    end
  end
  
  def check_overdue_loans
    # Find active loans that are overdue
    overdue_loans = Loan.where(status: :active)
                        .where("due_date < ?", Date.today)
    
    overdue_loans.find_each do |loan|
      days_overdue = (Date.today - loan.due_date.to_date).to_i
      
      # Only send notifications for specific thresholds to avoid spamming
      next unless [1, 3, 7, 14, 30].include?(days_overdue) || (days_overdue > 30 && days_overdue % 15 == 0)
      
      # Send notification to user
      UserNotificationService.new.notify_loan_overdue(loan, days_overdue)
      
      # For loans overdue by more than 30 days, notify admin about default risk
      if days_overdue >= 30
        AdminNotificationService.new.notify_loan_default_risk(loan)
      end
      
      # Log the reminder
      Rails.logger.info "Sent overdue notice for loan #{loan.reference_number}, #{days_overdue} days overdue"
    end
  end
end
