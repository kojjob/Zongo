class CreditScoreUpdateService
  def initialize(user)
    @user = user
    @credit_score_service = CreditScoreService.new(user)
  end

  def update_after_loan_repayment(loan, amount)
    # Get the current credit score
    current_score = @user.current_credit_score&.score || 500
    
    # Calculate the percentage of the loan that was repaid
    repayment_percentage = (amount / loan.amount_due) * 100
    
    # Calculate the days from due date (negative if paid early, positive if paid late)
    days_from_due_date = if loan.due_date.present?
                          (Date.today - loan.due_date.to_date).to_i
                        else
                          0
                        end
    
    # Calculate score adjustment based on repayment percentage and timing
    score_adjustment = calculate_score_adjustment(repayment_percentage, days_from_due_date)
    
    # Create a new credit score record with the adjustment
    update_credit_score(current_score + score_adjustment, {
      previous_score: current_score,
      adjustment: score_adjustment,
      reason: "Loan repayment",
      loan_id: loan.id,
      repayment_percentage: repayment_percentage,
      days_from_due_date: days_from_due_date
    })
    
    # Return the adjustment
    score_adjustment
  end
  
  def update_after_loan_completion(loan)
    # Get the current credit score
    current_score = @user.current_credit_score&.score || 500
    
    # Calculate days from loan creation to completion
    loan_duration_days = (loan.completed_at.to_date - loan.created_at.to_date).to_i
    expected_duration = loan.term_days
    
    # Calculate if loan was paid on time
    on_time = loan_duration_days <= expected_duration
    
    # Calculate score adjustment
    score_adjustment = on_time ? 25 : 10
    
    # Create a new credit score record with the adjustment
    update_credit_score(current_score + score_adjustment, {
      previous_score: current_score,
      adjustment: score_adjustment,
      reason: "Loan completed",
      loan_id: loan.id,
      on_time: on_time,
      loan_duration_days: loan_duration_days,
      expected_duration: expected_duration
    })
    
    # Return the adjustment
    score_adjustment
  end
  
  def update_after_loan_default(loan)
    # Get the current credit score
    current_score = @user.current_credit_score&.score || 500
    
    # Calculate days overdue
    days_overdue = (Date.today - loan.due_date.to_date).to_i
    
    # Calculate score adjustment (negative impact)
    score_adjustment = calculate_default_adjustment(days_overdue)
    
    # Create a new credit score record with the adjustment
    update_credit_score(current_score + score_adjustment, {
      previous_score: current_score,
      adjustment: score_adjustment,
      reason: "Loan defaulted",
      loan_id: loan.id,
      days_overdue: days_overdue
    })
    
    # Return the adjustment
    score_adjustment
  end
  
  private
  
  def calculate_score_adjustment(repayment_percentage, days_from_due_date)
    # Base adjustment based on repayment percentage
    base_adjustment = if repayment_percentage >= 100
                        15  # Full repayment
                      elsif repayment_percentage >= 50
                        10  # Substantial repayment
                      elsif repayment_percentage >= 25
                        5   # Partial repayment
                      else
                        2   # Minimal repayment
                      end
    
    # Timing adjustment
    timing_adjustment = if days_from_due_date < -7
                          10  # Paid more than a week early
                        elsif days_from_due_date < 0
                          5   # Paid early
                        elsif days_from_due_date == 0
                          0   # Paid on time
                        elsif days_from_due_date <= 3
                          -2  # Slightly late
                        elsif days_from_due_date <= 7
                          -5  # Late
                        elsif days_from_due_date <= 14
                          -10 # Very late
                        else
                          -15 # Extremely late
                        end
    
    # Total adjustment
    base_adjustment + timing_adjustment
  end
  
  def calculate_default_adjustment(days_overdue)
    # Negative impact based on how long the loan has been in default
    if days_overdue > 90
      -100  # Severe impact for long-term default
    elsif days_overdue > 60
      -75   # Major impact
    elsif days_overdue > 30
      -50   # Significant impact
    else
      -25   # Moderate impact
    end
  end
  
  def update_credit_score(new_score, metadata)
    # Ensure score is within valid range
    new_score = [[new_score, 850].min, 300].max
    
    # Get existing factors or create new ones
    current_score = @user.current_credit_score
    factors = current_score&.factors.present? ? JSON.parse(current_score.factors) : {}
    
    # Add new metadata to factors
    factors["last_update"] = metadata
    
    # Create new credit score record
    @user.credit_scores.create!(
      score: new_score,
      calculated_at: Time.current,
      factors: factors.to_json,
      is_current: true
    )
  end
end
