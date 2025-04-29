class CreditScoreRecommendationsService
  def initialize(user)
    @user = user
    @factors_service = CreditScoreFactorsService.new(user)
    @analysis = @factors_service.analyze
  end

  # Generate personalized recommendations for improving credit score
  def generate_recommendations
    return [] unless @analysis.present? && @analysis[:score].present?
    
    # Start with recommendations based on weak areas
    recommendations = recommendations_from_weak_areas
    
    # Add general recommendations based on score level
    recommendations += general_recommendations_by_score_level
    
    # Add recommendations based on recent activity
    recommendations += recommendations_from_recent_activity
    
    # Add recommendations based on user profile
    recommendations += recommendations_from_user_profile
    
    # Sort by impact (highest first) and limit to top 5
    recommendations.sort_by { |r| -r[:impact] }.uniq { |r| r[:action] }.take(5)
  end
  
  # Generate a credit improvement plan with steps and timeline
  def generate_improvement_plan
    recommendations = generate_recommendations
    
    # Calculate potential score improvement
    potential_improvement = recommendations.sum { |r| r[:impact] }
    potential_new_score = [[@analysis[:score] + potential_improvement, 850].min, 300].max
    
    # Create a timeline for improvements
    timeline = create_improvement_timeline(recommendations)
    
    {
      current_score: @analysis[:score],
      potential_score: potential_new_score,
      improvement: potential_improvement,
      steps: recommendations,
      timeline: timeline
    }
  end
  
  private
  
  def recommendations_from_weak_areas
    recommendations = []
    
    @analysis[:weak_areas].each do |weak_area|
      case weak_area
      when :account_age
        recommendations << {
          action: "Keep your account active with regular usage",
          description: "Your account age score will improve naturally over time. Make sure to log in regularly and use your account.",
          impact: @analysis[:improvement_potential].dig(:account_age, :potential_points) || 5,
          difficulty: :easy,
          timeframe: :long_term,
          category: :account_age
        }
      when :transaction_history
        recommendations << {
          action: "Use your wallet for regular transactions",
          description: "Make at least 5-10 transactions per month using your wallet to build a solid transaction history.",
          impact: @analysis[:improvement_potential].dig(:transaction_history, :potential_points) || 10,
          difficulty: :easy,
          timeframe: :short_term,
          category: :transaction_history
        }
        
        recommendations << {
          action: "Set up recurring bill payments through your wallet",
          description: "Automating regular payments helps build a consistent transaction history.",
          impact: 15,
          difficulty: :medium,
          timeframe: :medium_term,
          category: :transaction_history
        }
      when :loan_history
        recommendations << {
          action: "Repay any existing loans on time",
          description: "Making timely repayments is the most important factor for improving your loan history score.",
          impact: 25,
          difficulty: :medium,
          timeframe: :short_term,
          category: :loan_history
        }
        
        if @user.loans.completed.count < 2
          recommendations << {
            action: "Consider taking a small loan and repaying it quickly",
            description: "Successfully completing a loan cycle demonstrates creditworthiness.",
            impact: 30,
            difficulty: :medium,
            timeframe: :medium_term,
            category: :loan_history
          }
        end
      when :verification
        recommendations << {
          action: "Complete identity verification",
          description: "Verify your identity to significantly boost your credit score.",
          impact: @analysis[:improvement_potential].dig(:verification, :potential_points) || 20,
          difficulty: :easy,
          timeframe: :immediate,
          category: :verification
        }
      end
    end
    
    recommendations
  end
  
  def general_recommendations_by_score_level
    case @analysis[:score_level]
    when :excellent
      [
        {
          action: "Maintain your excellent credit habits",
          description: "Continue your good practices to maintain your excellent score.",
          impact: 0,
          difficulty: :easy,
          timeframe: :ongoing,
          category: :general
        }
      ]
    when :very_good, :good
      [
        {
          action: "Avoid taking on too many loans at once",
          description: "Multiple simultaneous loans can negatively impact your score.",
          impact: 10,
          difficulty: :medium,
          timeframe: :ongoing,
          category: :general
        }
      ]
    when :fair
      [
        {
          action: "Pay off any overdue amounts immediately",
          description: "Clearing overdue balances can quickly improve your score.",
          impact: 20,
          difficulty: :medium,
          timeframe: :immediate,
          category: :general
        },
        {
          action: "Avoid applying for multiple loans in a short period",
          description: "Multiple loan applications can signal financial distress.",
          impact: 15,
          difficulty: :easy,
          timeframe: :ongoing,
          category: :general
        }
      ]
    when :poor, :very_poor
      [
        {
          action: "Clear any defaulted loans",
          description: "Defaulted loans severely impact your score. Clearing them should be your top priority.",
          impact: 40,
          difficulty: :hard,
          timeframe: :immediate,
          category: :general
        },
        {
          action: "Consider a secured loan to rebuild credit",
          description: "A small secured loan can help rebuild your credit history.",
          impact: 25,
          difficulty: :medium,
          timeframe: :short_term,
          category: :general
        }
      ]
    else
      []
    end
  end
  
  def recommendations_from_recent_activity
    recommendations = []
    recent_changes = @analysis[:recent_changes]
    
    if recent_changes.present?
      if recent_changes["reason"] == "Loan defaulted"
        recommendations << {
          action: "Settle your defaulted loan as soon as possible",
          description: "Your score recently dropped due to a defaulted loan. Settling this debt should be your priority.",
          impact: 35,
          difficulty: :hard,
          timeframe: :immediate,
          category: :recent_activity
        }
      elsif recent_changes["reason"] == "Loan repayment" && recent_changes["adjustment"].to_i < 0
        recommendations << {
          action: "Make loan repayments on time",
          description: "Your score was recently affected by a late loan repayment. Try to make future payments on time.",
          impact: 20,
          difficulty: :medium,
          timeframe: :short_term,
          category: :recent_activity
        }
      end
    end
    
    # Check for recent loan applications
    if @user.loans.where("created_at > ?", 30.days.ago).count > 2
      recommendations << {
        action: "Limit new loan applications",
        description: "You've applied for multiple loans recently. This can negatively impact your score.",
        impact: 15,
        difficulty: :easy,
        timeframe: :immediate,
        category: :recent_activity
      }
    end
    
    recommendations
  end
  
  def recommendations_from_user_profile
    recommendations = []
    
    # Check if user has completed their profile
    unless @user.profile_complete?
      recommendations << {
        action: "Complete your user profile",
        description: "A complete profile helps establish your identity and improves your creditworthiness.",
        impact: 10,
        difficulty: :easy,
        timeframe: :immediate,
        category: :profile
      }
    end
    
    # Check if user has a payment method
    if @user.payment_methods.count == 0
      recommendations << {
        action: "Add a payment method to your account",
        description: "Having a verified payment method improves your account standing.",
        impact: 5,
        difficulty: :easy,
        timeframe: :immediate,
        category: :profile
      }
    end
    
    # Check wallet activity
    if @user.wallet && @user.wallet.transactions.where("created_at > ?", 30.days.ago).count < 3
      recommendations << {
        action: "Increase your wallet activity",
        description: "Regular wallet usage demonstrates financial engagement and improves your score.",
        impact: 15,
        difficulty: :easy,
        timeframe: :short_term,
        category: :transaction_history
      }
    end
    
    recommendations
  end
  
  def create_improvement_timeline(recommendations)
    timeline = {
      immediate: [],
      short_term: [], # 1-30 days
      medium_term: [], # 1-3 months
      long_term: [], # 3+ months
      ongoing: []
    }
    
    recommendations.each do |recommendation|
      timeline[recommendation[:timeframe]] << {
        action: recommendation[:action],
        impact: recommendation[:impact]
      }
    end
    
    timeline
  end
end
