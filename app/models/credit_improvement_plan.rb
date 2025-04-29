class CreditImprovementPlan < ApplicationRecord
  belongs_to :user
  has_many :credit_improvement_steps, dependent: :destroy
  
  # Statuses
  enum status: {
    active: 0,
    completed: 1,
    abandoned: 2
  }
  
  # Scopes
  scope :current, -> { where(status: :active) }
  
  # Calculate progress percentage
  def progress_percentage
    return 0 if credit_improvement_steps.empty?
    
    completed_steps = credit_improvement_steps.where(status: :completed).count
    (completed_steps.to_f / credit_improvement_steps.count * 100).round
  end
  
  # Check if the plan is on track
  def on_track?
    return true if completed?
    return false if abandoned?
    
    # Check if we're meeting the expected progress based on time elapsed
    days_elapsed = (Date.today - created_at.to_date).to_i
    days_total = (end_date - created_at.to_date).to_i
    
    return true if days_total.zero?
    
    expected_progress = (days_elapsed.to_f / days_total * 100).round
    progress_percentage >= expected_progress
  end
  
  # Generate a new plan for a user
  def self.generate_for(user)
    # Get recommendations
    recommendations_service = CreditScoreRecommendationsService.new(user)
    plan_data = recommendations_service.generate_improvement_plan
    
    # Create the plan
    plan = user.credit_improvement_plans.create!(
      starting_score: plan_data[:current_score],
      target_score: plan_data[:potential_score],
      start_date: Date.today,
      end_date: Date.today + 90.days,
      status: :active
    )
    
    # Create steps for the plan
    plan_data[:steps].each_with_index do |step, index|
      plan.credit_improvement_steps.create!(
        action: step[:action],
        description: step[:description],
        impact: step[:impact],
        timeframe: step[:timeframe],
        difficulty: step[:difficulty],
        category: step[:category],
        status: :pending,
        position: index + 1
      )
    end
    
    plan
  end
  
  # Check if the plan needs to be updated
  def needs_update?
    # Update if the plan is more than 30 days old or if the user's score has changed significantly
    days_since_update = (Date.today - updated_at.to_date).to_i
    current_score = user.current_credit_score&.score || 0
    score_difference = (current_score - starting_score).abs
    
    days_since_update > 30 || score_difference > 50
  end
  
  # Update the plan based on current user data
  def update_plan!
    # Get new recommendations
    recommendations_service = CreditScoreRecommendationsService.new(user)
    plan_data = recommendations_service.generate_improvement_plan
    
    # Update the plan
    update!(
      target_score: plan_data[:potential_score],
      updated_at: Time.current
    )
    
    # Mark completed steps
    credit_improvement_steps.each do |step|
      if step.should_be_completed?
        step.update(status: :completed)
      end
    end
    
    # Add new steps if needed
    existing_actions = credit_improvement_steps.pluck(:action)
    
    plan_data[:steps].each_with_index do |step, index|
      next if existing_actions.include?(step[:action])
      
      credit_improvement_steps.create!(
        action: step[:action],
        description: step[:description],
        impact: step[:impact],
        timeframe: step[:timeframe],
        difficulty: step[:difficulty],
        category: step[:category],
        status: :pending,
        position: credit_improvement_steps.maximum(:position).to_i + 1
      )
    end
    
    # Check if plan is completed
    if progress_percentage == 100
      update(status: :completed)
    end
    
    self
  end
end
