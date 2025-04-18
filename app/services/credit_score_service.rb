class CreditScoreService
  def initialize(user)
    @user = user
  end

  def calculate
    # Factors to consider:
    # 1. Transaction history
    # 2. Previous loan repayment history
    # 3. Account age
    # 4. Identity verification status
    # 5. Income stability

    base_score = 500

    # Add points for account age
    account_age_days = (Time.current - @user.created_at).to_i / 1.day
    account_age_score = [ account_age_days / 30, 100 ].min

    # Add points for transaction history
    transaction_count = @user.wallet&.transactions&.count || 0
    transaction_score = [ transaction_count / 5, 100 ].min

    # Add points for previous loan history
    loan_history_score = calculate_loan_history_score

    # Add points for identity verification
    verification_score = @user.has_verified_identity? ? 100 : 0

    # Calculate final score (300-850 range)
    final_score = base_score +
                 (account_age_score * 0.1).to_i +
                 (transaction_score * 0.2).to_i +
                 (loan_history_score * 0.5).to_i +
                 (verification_score * 0.2).to_i

    # Ensure score is within valid range
    final_score = [ [ final_score, 850 ].min, 300 ].max

    # Save the credit score
    credit_score = @user.credit_scores.create!(
      score: final_score,
      calculated_at: Time.current,
      score_factors: {
        account_age: account_age_score,
        transaction_history: transaction_score,
        loan_history: loan_history_score,
        verification: verification_score
      },
      is_current: true
    )

    # Return score data
    {
      score: final_score,
      factors: credit_score.score_factors,
      calculated_at: credit_score.calculated_at
    }
  end

  private

  def calculate_loan_history_score
    completed_loans = @user.loans.completed.count
    defaulted_loans = @user.loans.defaulted.count

    if completed_loans == 0 && defaulted_loans == 0
      return 50 # Neutral score for no history
    end

    # Calculate ratio of good to total loans
    total_loans = completed_loans + defaulted_loans
    good_ratio = completed_loans.to_f / total_loans

    # Convert to score (0-100)
    (good_ratio * 100).to_i
  end
end
