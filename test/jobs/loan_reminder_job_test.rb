require "test_helper"

class LoanReminderJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
    @wallet = wallets(:one)
  end
  
  test "should send reminders for upcoming payments" do
    # Create a loan with a payment due in 2 days
    loan = Loan.create!(
      user: @user,
      wallet: @wallet,
      loan_type: "microloan",
      amount: 100.0,
      interest_rate: 5.0,
      processing_fee: 1.0,
      term_days: 30,
      due_date: 2.days.from_now,
      status: "active",
      current_balance: 105.0
    )
    
    # Mock the UserNotificationService to track calls
    mock_service = Minitest::Mock.new
    mock_service.expect :notify_loan_due_soon, nil, [loan, 2]
    
    # Replace the actual service with our mock
    UserNotificationService.stub :new, mock_service do
      # Run the job
      LoanReminderJob.perform_now
    end
    
    # Verify that the mock was called as expected
    assert_mock mock_service
  end
  
  test "should send reminders for overdue payments" do
    # Create a loan that is overdue by 1 day
    loan = Loan.create!(
      user: @user,
      wallet: @wallet,
      loan_type: "microloan",
      amount: 100.0,
      interest_rate: 5.0,
      processing_fee: 1.0,
      term_days: 30,
      due_date: 1.day.ago,
      status: "active",
      current_balance: 105.0
    )
    
    # Mock the UserNotificationService to track calls
    mock_service = Minitest::Mock.new
    mock_service.expect :notify_loan_overdue, nil, [loan, 1]
    
    # Replace the actual service with our mock
    UserNotificationService.stub :new, mock_service do
      # Run the job
      LoanReminderJob.perform_now
    end
    
    # Verify that the mock was called as expected
    assert_mock mock_service
  end
  
  test "should notify admin for loans at risk of default" do
    # Create a loan that is overdue by 30 days
    loan = Loan.create!(
      user: @user,
      wallet: @wallet,
      loan_type: "microloan",
      amount: 100.0,
      interest_rate: 5.0,
      processing_fee: 1.0,
      term_days: 30,
      due_date: 30.days.ago,
      status: "active",
      current_balance: 105.0
    )
    
    # Mock the UserNotificationService and AdminNotificationService to track calls
    user_mock = Minitest::Mock.new
    user_mock.expect :notify_loan_overdue, nil, [loan, 30]
    
    admin_mock = Minitest::Mock.new
    admin_mock.expect :notify_loan_default_risk, nil, [loan]
    
    # Replace the actual services with our mocks
    UserNotificationService.stub :new, user_mock do
      AdminNotificationService.stub :new, admin_mock do
        # Run the job
        LoanReminderJob.perform_now
      end
    end
    
    # Verify that the mocks were called as expected
    assert_mock user_mock
    assert_mock admin_mock
  end
end
