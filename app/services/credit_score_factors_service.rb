class CreditScoreFactorsService
  def initialize(user)
    @user = user
    @current_score = user.current_credit_score
    @factors = parse_factors
  end

  # Analyze the user's credit score factors and return a breakdown
  def analyze
    return {} unless @current_score.present?

    {
      score: @current_score.score,
      score_level: score_level,
      score_breakdown: score_breakdown,
      weak_areas: identify_weak_areas,
      strong_areas: identify_strong_areas,
      recent_changes: recent_changes,
      improvement_potential: calculate_improvement_potential
    }
  end

  private

  def parse_factors
    return {} unless @current_score&.factors.present?
    
    begin
      JSON.parse(@current_score.factors)
    rescue JSON::ParserError
      {}
    end
  end

  def score_level
    case @current_score.score
    when 750..850 then :excellent
    when 700..749 then :very_good
    when 650..699 then :good
    when 600..649 then :fair
    when 550..599 then :poor
    else :very_poor
    end
  end

  def score_breakdown
    # Extract the score breakdown from factors
    # Default values if specific factors aren't available
    {
      account_age: @factors["account_age"] || 0,
      transaction_history: @factors["transaction_history"] || 0,
      loan_history: @factors["loan_history"] || 0,
      verification: @factors["verification"] || 0
    }
  end

  def identify_weak_areas
    # Identify factors with scores below 60 (out of 100)
    score_breakdown.select { |factor, score| score < 60 }.keys
  end

  def identify_strong_areas
    # Identify factors with scores above 80 (out of 100)
    score_breakdown.select { |factor, score| score >= 80 }.keys
  end

  def recent_changes
    # Get the last update information if available
    @factors["last_update"] || {}
  end

  def calculate_improvement_potential
    # Calculate how much the score could improve with specific actions
    potential = {}
    
    # Account age improvement potential
    if score_breakdown[:account_age] < 100
      potential[:account_age] = {
        action: "Keep your account active",
        potential_points: [(100 - score_breakdown[:account_age]) / 5, 20].min
      }
    end
    
    # Transaction history improvement potential
    if score_breakdown[:transaction_history] < 100
      potential[:transaction_history] = {
        action: "Use your wallet for regular transactions",
        potential_points: [(100 - score_breakdown[:transaction_history]) / 4, 25].min
      }
    end
    
    # Loan history improvement potential
    if score_breakdown[:loan_history] < 100
      potential[:loan_history] = {
        action: "Repay loans on time",
        potential_points: [(100 - score_breakdown[:loan_history]) / 2, 50].min
      }
    end
    
    # Verification improvement potential
    if score_breakdown[:verification] < 100
      potential[:verification] = {
        action: "Complete identity verification",
        potential_points: score_breakdown[:verification] == 0 ? 100 : 0
      }
    end
    
    potential
  end
end
