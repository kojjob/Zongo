require 'test_helper'

class CreditScoreUpdateJobTest < ActiveJob::TestCase
  test "updates scores for users with recent loan activity" do
    # Create a user with a recent loan repayment
    user = users(:one)
    loan = loans(:active_loan)
    
    # Create a loan repayment in the last 24 hours
    repayment = LoanRepayment.create!(
      loan: loan,
      amount: 100,
      payment_method: "wallet",
      created_at: 12.hours.ago
    )
    
    # Create another user with a recently completed loan
    user2 = users(:two)
    loan2 = loans(:pending_loan)
    loan2.update(
      status: :completed,
      completed_at: 6.hours.ago
    )
    
    # Create a third user with a recently defaulted loan
    user3 = users(:admin)
    loan3 = loans(:approved_loan)
    loan3.update(
      status: :defaulted,
      defaulted_at: 8.hours.ago
    )
    
    # Mock the CreditScoreService to verify it's called for each user
    mock_service = Minitest::Mock.new
    mock_service.expect :calculate, { score: 700 }
    mock_service.expect :calculate, { score: 650 }
    mock_service.expect :calculate, { score: 500 }
    
    CreditScoreService.stub :new, mock_service do
      # Run the job
      CreditScoreUpdateJob.perform_now
    end
    
    # Verify all expected calls were made
    assert_mock mock_service
  end
  
  test "updates scores for users with outdated scores" do
    # Create a user with an outdated credit score
    user = users(:one)
    user.credit_scores.create!(
      score: 600,
      calculated_at: 40.days.ago,
      is_current: true
    )
    
    # Create a user with no credit score
    user2 = users(:two)
    user2.credit_scores.destroy_all
    
    # Mock the CreditScoreService to verify it's called for each user
    mock_service = Minitest::Mock.new
    mock_service.expect :calculate, { score: 700 }
    mock_service.expect :calculate, { score: 650 }
    
    CreditScoreService.stub :new, mock_service do
      # Run the job
      CreditScoreUpdateJob.perform_now
    end
    
    # Verify all expected calls were made
    assert_mock mock_service
  end
end
