class CreditImprovementStep < ApplicationRecord
  belongs_to :credit_improvement_plan
  
  # Enums
  enum status: {
    pending: 0,
    in_progress: 1,
    completed: 2,
    skipped: 3
  }
  
  enum timeframe: {
    immediate: 0,
    short_term: 1,
    medium_term: 2,
    long_term: 3,
    ongoing: 4
  }
  
  enum difficulty: {
    easy: 0,
    medium: 1,
    hard: 2
  }
  
  enum category: {
    account_age: 0,
    transaction_history: 1,
    loan_history: 2,
    verification: 3,
    general: 4,
    recent_activity: 5,
    profile: 6
  }
  
  # Validations
  validates :action, presence: true
  validates :description, presence: true
  validates :impact, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :position, presence: true, numericality: { greater_than: 0 }
  
  # Scopes
  scope :ordered, -> { order(position: :asc) }
  scope :active, -> { where(status: [:pending, :in_progress]) }
  
  # Get the user associated with this step
  def user
    credit_improvement_plan.user
  end
  
  # Get the expected completion date based on timeframe
  def expected_completion_date
    case timeframe
    when "immediate"
      credit_improvement_plan.start_date + 3.days
    when "short_term"
      credit_improvement_plan.start_date + 30.days
    when "medium_term"
      credit_improvement_plan.start_date + 60.days
    when "long_term"
      credit_improvement_plan.start_date + 90.days
    when "ongoing"
      credit_improvement_plan.end_date
    end
  end
  
  # Check if the step is overdue
  def overdue?
    return false if completed? || skipped?
    
    Date.today > expected_completion_date
  end
  
  # Check if the step should be automatically marked as completed
  def should_be_completed?
    return false if completed? || skipped?
    
    user = credit_improvement_plan.user
    
    case category
    when "verification"
      user.verified?
    when "profile"
      user.profile_complete?
    when "transaction_history"
      if action.include?("regular transactions")
        user.wallet.transactions.where("created_at > ?", 30.days.ago).count >= 5
      elsif action.include?("recurring bill payments")
        user.scheduled_transactions.active.count > 0
      else
        false
      end
    when "loan_history"
      if action.include?("existing loans")
        user.loans.active.none? { |loan| loan.overdue? }
      elsif action.include?("small loan")
        user.loans.completed.where("completed_at > ?", credit_improvement_plan.start_date).exists?
      else
        false
      end
    when "recent_activity"
      if action.include?("defaulted loan")
        user.loans.defaulted.none?
      else
        false
      end
    else
      false
    end
  end
  
  # Mark the step as completed and update the plan
  def complete!
    update!(status: :completed)
    
    # Check if all steps are completed
    if credit_improvement_plan.credit_improvement_steps.all? { |step| step.completed? || step.skipped? }
      credit_improvement_plan.update(status: :completed)
    end
  end
  
  # Get the icon for this step's category
  def category_icon
    case category
    when "account_age"
      "clock"
    when "transaction_history"
      "credit-card"
    when "loan_history"
      "document-text"
    when "verification"
      "shield-check"
    when "general"
      "star"
    when "recent_activity"
      "trending-up"
    when "profile"
      "user"
    else
      "information-circle"
    end
  end
end
