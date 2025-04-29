require "test_helper"

class LoansControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  
  setup do
    @user = users(:one)
    @loan = loans(:one)
    sign_in @user
  end

  test "should get index" do
    get loans_url
    assert_response :success
  end

  test "should get new" do
    get new_loan_url
    assert_response :success
  end

  test "should create loan" do
    assert_difference("Loan.count") do
      post loans_url, params: { 
        loan: { 
          loan_type: "microloan", 
          amount: 100.0, 
          term_days: 30 
        },
        terms: "1"
      }
    end

    assert_redirected_to loan_url(Loan.last)
  end

  test "should show loan" do
    get loan_url(@loan)
    assert_response :success
  end

  test "should get eligibility" do
    get eligibility_loans_url
    assert_response :success
  end

  test "should get types" do
    get types_loans_url
    assert_response :success
  end

  test "should get schedule" do
    get schedule_loan_url(@loan)
    assert_response :success
  end

  test "should get details" do
    get details_loan_url(@loan)
    assert_response :success
  end

  test "should process repayment" do
    # Set up a loan with an active status
    @loan.update(status: :active, current_balance: 100.0)
    
    # Process a repayment
    post repay_loan_url(@loan), params: { amount: 50.0 }
    
    # Reload the loan to get updated attributes
    @loan.reload
    
    # Check that the balance was reduced
    assert_equal 50.0, @loan.current_balance
    assert_redirected_to loan_url(@loan)
  end

  test "should not process invalid repayment" do
    # Set up a loan with an active status
    @loan.update(status: :active, current_balance: 100.0)
    
    # Try to process an invalid repayment (negative amount)
    post repay_loan_url(@loan), params: { amount: -50.0 }
    
    # Reload the loan to get updated attributes
    @loan.reload
    
    # Check that the balance was not changed
    assert_equal 100.0, @loan.current_balance
    assert_redirected_to loan_url(@loan)
  end

  test "should not allow unauthorized access" do
    # Sign out the current user
    sign_out @user
    
    # Try to access the loans index
    get loans_url
    
    # Should redirect to sign in
    assert_redirected_to new_user_session_path
  end
end
