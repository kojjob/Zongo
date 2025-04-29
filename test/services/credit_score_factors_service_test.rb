require 'test_helper'

class CreditScoreFactorsServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    
    # Create a credit score with factors
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
    
    @service = CreditScoreFactorsService.new(@user)
  end
  
  test "analyzes credit score factors" do
    analysis = @service.analyze
    
    assert_equal 650, analysis[:score]
    assert_equal :good, analysis[:score_level]
    
    # Check score breakdown
    assert_equal 70, analysis[:score_breakdown][:account_age]
    assert_equal 60, analysis[:score_breakdown][:transaction_history]
    assert_equal 50, analysis[:score_breakdown][:loan_history]
    assert_equal 80, analysis[:score_breakdown][:verification]
    
    # Check weak areas
    assert_includes analysis[:weak_areas], :loan_history
    
    # Check strong areas
    assert_includes analysis[:strong_areas], :verification
    
    # Check recent changes
    assert_equal "Loan repayment", analysis[:recent_changes]["reason"]
    assert_equal 20, analysis[:recent_changes]["adjustment"]
    
    # Check improvement potential
    assert_not_nil analysis[:improvement_potential][:loan_history]
    assert_equal "Repay loans on time", analysis[:improvement_potential][:loan_history][:action]
    assert analysis[:improvement_potential][:loan_history][:potential_points] > 0
  end
  
  test "handles missing credit score" do
    @user.credit_scores.destroy_all
    service = CreditScoreFactorsService.new(@user)
    
    analysis = service.analyze
    assert_empty analysis
  end
  
  test "handles invalid factors JSON" do
    @credit_score.update(factors: "invalid json")
    service = CreditScoreFactorsService.new(@user)
    
    analysis = service.analyze
    assert_equal 650, analysis[:score]
    assert_equal :good, analysis[:score_level]
    
    # Default values should be used
    assert_equal 0, analysis[:score_breakdown][:account_age]
    assert_equal 0, analysis[:score_breakdown][:transaction_history]
    assert_equal 0, analysis[:score_breakdown][:loan_history]
    assert_equal 0, analysis[:score_breakdown][:verification]
    
    # All areas should be weak
    assert_includes analysis[:weak_areas], :account_age
    assert_includes analysis[:weak_areas], :transaction_history]
    assert_includes analysis[:weak_areas], :loan_history]
    assert_includes analysis[:weak_areas], :verification]
    
    # No strong areas
    assert_empty analysis[:strong_areas]
    
    # No recent changes
    assert_empty analysis[:recent_changes]
  end
  
  test "correctly identifies score level" do
    score_levels = {
      300 => :very_poor,
      500 => :very_poor,
      550 => :poor,
      600 => :fair,
      650 => :good,
      700 => :very_good,
      800 => :excellent
    }
    
    score_levels.each do |score, expected_level|
      @credit_score.update(score: score)
      service = CreditScoreFactorsService.new(@user)
      analysis = service.analyze
      
      assert_equal expected_level, analysis[:score_level], "Score #{score} should be #{expected_level}"
    end
  end
end
