require 'test_helper'

class CreditScoreUpdateServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @loan = loans(:active_loan)
    @service = CreditScoreUpdateService.new(@user)
  end

  test "updates credit score after loan repayment" do
    # Create an initial credit score
    initial_score = 600
    @user.credit_scores.create!(
      score: initial_score,
      calculated_at: Time.current,
      is_current: true
    )

    # Make a loan repayment
    amount = @loan.amount_due * 0.5 # 50% repayment
    adjustment = @service.update_after_loan_repayment(@loan, amount)

    # Get the updated credit score
    updated_score = @user.current_credit_score

    # Verify the score was updated
    assert_not_nil updated_score
    assert_not_equal initial_score, updated_score.score
    assert_equal initial_score + adjustment, updated_score.score
    assert updated_score.is_current
    
    # Verify the factors contain the loan repayment information
    factors = JSON.parse(updated_score.factors)
    assert factors.key?("last_update")
    assert_equal "Loan repayment", factors["last_update"]["reason"]
    assert_equal initial_score, factors["last_update"]["previous_score"]
    assert_equal adjustment, factors["last_update"]["adjustment"]
  end

  test "updates credit score after loan completion" do
    # Create an initial credit score
    initial_score = 650
    @user.credit_scores.create!(
      score: initial_score,
      calculated_at: Time.current,
      is_current: true
    )

    # Complete a loan
    @loan.update(
      status: :completed,
      completed_at: Time.current
    )
    
    adjustment = @service.update_after_loan_completion(@loan)

    # Get the updated credit score
    updated_score = @user.current_credit_score

    # Verify the score was updated
    assert_not_nil updated_score
    assert_not_equal initial_score, updated_score.score
    assert_equal initial_score + adjustment, updated_score.score
    assert updated_score.is_current
    
    # Verify the factors contain the loan completion information
    factors = JSON.parse(updated_score.factors)
    assert factors.key?("last_update")
    assert_equal "Loan completed", factors["last_update"]["reason"]
    assert_equal initial_score, factors["last_update"]["previous_score"]
    assert_equal adjustment, factors["last_update"]["adjustment"]
  end

  test "updates credit score after loan default" do
    # Create an initial credit score
    initial_score = 700
    @user.credit_scores.create!(
      score: initial_score,
      calculated_at: Time.current,
      is_current: true
    )

    # Default a loan
    @loan.update(
      status: :defaulted,
      defaulted_at: Time.current,
      due_date: 30.days.ago
    )
    
    adjustment = @service.update_after_loan_default(@loan)

    # Get the updated credit score
    updated_score = @user.current_credit_score

    # Verify the score was updated
    assert_not_nil updated_score
    assert_not_equal initial_score, updated_score.score
    assert_equal initial_score + adjustment, updated_score.score
    assert updated_score.is_current
    
    # Verify the factors contain the loan default information
    factors = JSON.parse(updated_score.factors)
    assert factors.key?("last_update")
    assert_equal "Loan defaulted", factors["last_update"]["reason"]
    assert_equal initial_score, factors["last_update"]["previous_score"]
    assert_equal adjustment, factors["last_update"]["adjustment"]
    assert_equal 30, factors["last_update"]["days_overdue"]
  end

  test "ensures score stays within valid range" do
    # Test lower bound
    @user.credit_scores.create!(
      score: 310,
      calculated_at: Time.current,
      is_current: true
    )
    
    # Default a loan with a large negative impact
    @loan.update(
      status: :defaulted,
      defaulted_at: Time.current,
      due_date: 100.days.ago
    )
    
    @service.update_after_loan_default(@loan)
    
    # Score should not go below 300
    assert_equal 300, @user.current_credit_score.score
    
    # Test upper bound
    @user.credit_scores.destroy_all
    @user.credit_scores.create!(
      score: 840,
      calculated_at: Time.current,
      is_current: true
    )
    
    # Complete a loan with a positive impact
    @loan.update(
      status: :completed,
      completed_at: Time.current
    )
    
    @service.update_after_loan_completion(@loan)
    
    # Score should not go above 850
    assert @user.current_credit_score.score <= 850
  end
end
