require "test_helper"

class LoanTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @wallet = wallets(:one)
  end

  test "should create a valid loan" do
    loan = Loan.new(
      user: @user,
      wallet: @wallet,
      loan_type: "microloan",
      amount: 100.0,
      interest_rate: 5.0,
      processing_fee: 1.0,
      term_days: 30,
      due_date: 30.days.from_now,
      status: "pending"
    )
    
    assert loan.valid?
    assert loan.save
  end
  
  test "should not create a loan with invalid attributes" do
    # Test with negative amount
    loan = Loan.new(
      user: @user,
      wallet: @wallet,
      loan_type: "microloan",
      amount: -100.0,
      interest_rate: 5.0,
      processing_fee: 1.0,
      term_days: 30,
      due_date: 30.days.from_now,
      status: "pending"
    )
    
    assert_not loan.valid?
    
    # Test with missing required attributes
    loan = Loan.new(
      user: @user,
      wallet: @wallet
    )
    
    assert_not loan.valid?
  end
  
  test "should calculate correct amount due" do
    loan = Loan.new(
      user: @user,
      wallet: @wallet,
      loan_type: "microloan",
      amount: 100.0,
      interest_rate: 5.0,
      processing_fee: 1.0,
      term_days: 30,
      due_date: 30.days.from_now,
      status: "active"
    )
    
    # Calculate expected amount due
    # Principal + Interest + Processing Fee
    interest = 100.0 * 0.05 * (30.0 / 365.0)
    expected_amount = 100.0 + interest + 1.0
    
    assert_in_delta expected_amount, loan.get_amount_due, 0.01
  end
  
  test "should determine correct installment status" do
    loan = Loan.new(
      user: @user,
      wallet: @wallet,
      loan_type: "installment",
      amount: 1000.0,
      interest_rate: 15.0,
      processing_fee: 15.0,
      term_days: 90,
      due_date: 90.days.from_now,
      status: "active"
    )
    
    # Test for a date in the past
    past_date = 5.days.ago
    assert_equal "overdue", loan.determine_installment_status(past_date)
    
    # Test for today
    today = Time.current
    assert_equal "due", loan.determine_installment_status(today)
    
    # Test for a future date
    future_date = 5.days.from_now
    assert_equal "upcoming", loan.determine_installment_status(future_date)
    
    # Test for a completed loan
    loan.status = "completed"
    assert_equal "paid", loan.determine_installment_status(past_date)
  end
  
  test "should generate repayment schedule for installment loan" do
    loan = Loan.new(
      user: @user,
      wallet: @wallet,
      loan_type: "installment",
      amount: 1000.0,
      interest_rate: 15.0,
      processing_fee: 15.0,
      term_days: 90,
      due_date: 90.days.from_now,
      status: "active",
      disbursed_at: Time.current
    )
    
    schedule = loan.repayment_schedule
    
    # Should have 3 installments (90 days / 30 days per month)
    assert_equal 3, schedule.length
    
    # Each installment should have the required keys
    first_installment = schedule.first
    assert first_installment.key?(:installment_number)
    assert first_installment.key?(:due_date)
    assert first_installment.key?(:amount)
    assert first_installment.key?(:status)
    
    # Total of all installments should equal the total amount due
    total_installments = schedule.sum { |installment| installment[:amount] }
    assert_in_delta loan.get_amount_due, total_installments, 0.01
  end
end
