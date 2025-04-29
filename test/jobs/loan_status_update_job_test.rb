require "test_helper"

class LoanStatusUpdateJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
    @wallet = wallets(:one)
  end
  
  test "should mark overdue loans as defaulted" do
    # Create a loan that is overdue by more than DEFAULT_DAYS
    loan = Loan.create!(
      user: @user,
      wallet: @wallet,
      loan_type: "microloan",
      amount: 100.0,
      interest_rate: 5.0,
      processing_fee: 1.0,
      term_days: 30,
      due_date: (LoanStatusUpdateJob::DEFAULT_DAYS + 1).days.ago,
      status: "active",
      current_balance: 105.0
    )
    
    # Mock the notification services
    user_mock = Minitest::Mock.new
    user_mock.expect :notify_loan_defaulted, nil, [loan]
    
    admin_mock = Minitest::Mock.new
    admin_mock.expect :notify_loan_defaulted, nil, [loan]
    
    # Replace the actual services with our mocks
    UserNotificationService.stub :new, user_mock do
      AdminNotificationService.stub :new, admin_mock do
        # Run the job
        LoanStatusUpdateJob.perform_now
      end
    end
    
    # Reload the loan to get updated attributes
    loan.reload
    
    # Check that the loan status was updated
    assert_equal "defaulted", loan.status
    assert_not_nil loan.defaulted_at
    
    # Verify that the mocks were called as expected
    assert_mock user_mock
    assert_mock admin_mock
  end
  
  test "should not mark loans that are not overdue enough as defaulted" do
    # Create a loan that is overdue but by less than DEFAULT_DAYS
    loan = Loan.create!(
      user: @user,
      wallet: @wallet,
      loan_type: "microloan",
      amount: 100.0,
      interest_rate: 5.0,
      processing_fee: 1.0,
      term_days: 30,
      due_date: (LoanStatusUpdateJob::DEFAULT_DAYS - 1).days.ago,
      status: "active",
      current_balance: 105.0
    )
    
    # Run the job
    LoanStatusUpdateJob.perform_now
    
    # Reload the loan to get updated attributes
    loan.reload
    
    # Check that the loan status was not updated
    assert_equal "active", loan.status
    assert_nil loan.defaulted_at
  end
  
  test "should not mark non-active loans as defaulted" do
    # Create a loan that is overdue by more than DEFAULT_DAYS but not active
    loan = Loan.create!(
      user: @user,
      wallet: @wallet,
      loan_type: "microloan",
      amount: 100.0,
      interest_rate: 5.0,
      processing_fee: 1.0,
      term_days: 30,
      due_date: (LoanStatusUpdateJob::DEFAULT_DAYS + 1).days.ago,
      status: "completed",
      current_balance: 0.0
    )
    
    # Run the job
    LoanStatusUpdateJob.perform_now
    
    # Reload the loan to get updated attributes
    loan.reload
    
    # Check that the loan status was not updated
    assert_equal "completed", loan.status
    assert_nil loan.defaulted_at
  end
end
