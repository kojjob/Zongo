class CreditScoreUpdateJob < ApplicationJob
  queue_as :default

  def perform
    # Find users who need their credit scores updated
    # This includes users with:
    # 1. Recent loan repayments
    # 2. Recently completed loans
    # 3. No credit score in the last 30 days
    
    # Update scores for users with recent loan activity
    update_scores_for_users_with_recent_activity
    
    # Periodically update scores for all users (monthly)
    update_scores_periodically
  end
  
  private
  
  def update_scores_for_users_with_recent_activity
    # Find users with loan repayments in the last 24 hours
    recent_repayment_user_ids = LoanRepayment.where('created_at > ?', 24.hours.ago)
                                            .pluck(:loan_id)
                                            .map { |loan_id| Loan.find_by(id: loan_id)&.user_id }
                                            .compact
                                            .uniq
    
    # Find users with loans completed in the last 24 hours
    recent_completion_user_ids = Loan.where(status: :completed)
                                    .where('completed_at > ?', 24.hours.ago)
                                    .pluck(:user_id)
                                    .uniq
    
    # Find users with loans defaulted in the last 24 hours
    recent_default_user_ids = Loan.where(status: :defaulted)
                                 .where('defaulted_at > ?', 24.hours.ago)
                                 .pluck(:user_id)
                                 .uniq
    
    # Combine all user IDs
    user_ids = (recent_repayment_user_ids + recent_completion_user_ids + recent_default_user_ids).uniq
    
    # Update credit scores for these users
    User.where(id: user_ids).find_each do |user|
      CreditScoreService.new(user).calculate
    end
  end
  
  def update_scores_periodically
    # Find users who haven't had their credit score updated in the last 30 days
    outdated_score_user_ids = User.joins(:credit_scores)
                                 .where('credit_scores.calculated_at < ?', 30.days.ago)
                                 .where('credit_scores.is_current = ?', true)
                                 .pluck(:id)
                                 .uniq
    
    # Find users who don't have any credit score yet
    no_score_user_ids = User.left_outer_joins(:credit_scores)
                           .where(credit_scores: { id: nil })
                           .pluck(:id)
                           .uniq
    
    # Combine all user IDs
    user_ids = (outdated_score_user_ids + no_score_user_ids).uniq
    
    # Update credit scores for these users
    User.where(id: user_ids).find_each do |user|
      CreditScoreService.new(user).calculate
    end
  end
end
