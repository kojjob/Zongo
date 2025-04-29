require 'test_helper'

class CreditImprovementControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  
  setup do
    @user = users(:one)
    sign_in @user
    
    # Create a credit score for the user
    @credit_score = @user.credit_scores.create!(
      score: 650,
      calculated_at: Time.current,
      is_current: true,
      factors: {
        account_age: 70,
        transaction_history: 60,
        loan_history: 50,
        verification: 80,
        last_update: {
          previous_score: 630,
          adjustment: 20,
          reason: "Loan repayment"
        }
      }.to_json
    )
  end
  
  test "should get index" do
    get credit_improvement_index_url
    assert_response :success
    assert_not_nil assigns(:current_score)
    assert_not_nil assigns(:analysis)
    assert_not_nil assigns(:recommendations)
  end
  
  test "should create plan" do
    assert_difference('CreditImprovementPlan.count') do
      post credit_improvement_create_plan_url
    end
    
    assert_redirected_to credit_improvement_path(CreditImprovementPlan.last)
    assert_equal @user.id, CreditImprovementPlan.last.user_id
  end
  
  test "should show plan" do
    plan = CreditImprovementPlan.generate_for(@user)
    
    get credit_improvement_url(plan)
    assert_response :success
    assert_not_nil assigns(:steps)
    assert_not_nil assigns(:progress)
  end
  
  test "should update step" do
    plan = CreditImprovementPlan.generate_for(@user)
    step = plan.credit_improvement_steps.first
    
    patch update_step_credit_improvement_url(plan, params: { step_id: step.id, status: "in_progress" })
    assert_redirected_to credit_improvement_path(plan)
    
    step.reload
    assert step.in_progress?
  end
  
  test "should refresh plan" do
    plan = CreditImprovementPlan.generate_for(@user)
    original_updated_at = plan.updated_at
    
    # Wait a moment to ensure updated_at will be different
    sleep(1)
    
    post refresh_plan_credit_improvement_url(plan)
    assert_redirected_to credit_improvement_path(plan)
    
    plan.reload
    assert_not_equal original_updated_at, plan.updated_at
  end
  
  test "should not allow access to another user's plan" do
    other_user = users(:two)
    other_plan = CreditImprovementPlan.generate_for(other_user)
    
    get credit_improvement_url(other_plan)
    assert_redirected_to credit_improvement_index_path
    assert_equal "You don't have access to this plan.", flash[:alert]
  end
end
