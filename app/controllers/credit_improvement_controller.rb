class CreditImprovementController < ApplicationController
  before_action :authenticate_user!
  before_action :set_credit_improvement_plan, only: [:show, :update_step, :refresh_plan]
  
  def index
    @current_score = current_user.current_credit_score
    
    if @current_score.present?
      # Get credit score analysis
      @factors_service = CreditScoreFactorsService.new(current_user)
      @analysis = @factors_service.analyze
      
      # Get recommendations
      @recommendations_service = CreditScoreRecommendationsService.new(current_user)
      @recommendations = @recommendations_service.generate_recommendations
      
      # Get current improvement plan if it exists
      @plan = current_user.current_credit_improvement_plan
      
      # Get improvement progress
      @progress = current_user.credit_improvement_progress if @plan.present?
    end
    
    # Get credit score history
    @score_history = current_user.credit_scores.order(calculated_at: :desc).limit(10)
  end
  
  def create_plan
    # Check if user already has an active plan
    if current_user.has_active_credit_improvement_plan?
      redirect_to credit_improvement_path(current_user.current_credit_improvement_plan), 
                  notice: "You already have an active credit improvement plan."
      return
    end
    
    # Create a new plan
    @plan = CreditImprovementPlan.generate_for(current_user)
    
    if @plan.persisted?
      # Create a notification for the user
      current_user.create_notification(
        title: "Credit Improvement Plan Created",
        content: "Your personalized credit improvement plan is ready. Start improving your credit score today!",
        notification_type: "credit_score",
        source_type: "CreditImprovementPlan",
        source_id: @plan.id
      )
      
      redirect_to credit_improvement_path(@plan), notice: "Your credit improvement plan has been created!"
    else
      redirect_to credit_improvement_index_path, alert: "Could not create a credit improvement plan. Please try again."
    end
  end
  
  def show
    @steps = @plan.credit_improvement_steps.ordered
    
    # Get credit score analysis
    @factors_service = CreditScoreFactorsService.new(current_user)
    @analysis = @factors_service.analyze
    
    # Get progress information
    @progress = current_user.credit_improvement_progress
    
    # Get credit score history
    @score_history = current_user.credit_scores.order(calculated_at: :desc).limit(10)
  end
  
  def update_step
    @step = @plan.credit_improvement_steps.find(params[:step_id])
    
    case params[:status]
    when "in_progress"
      @step.update(status: :in_progress)
      flash[:notice] = "Step marked as in progress."
    when "completed"
      @step.complete!
      
      # Create a notification for the user
      current_user.create_notification(
        title: "Credit Improvement Step Completed",
        content: "You've completed the step: #{@step.action}. Keep up the good work!",
        notification_type: "credit_score",
        source_type: "CreditImprovementStep",
        source_id: @step.id
      )
      
      flash[:notice] = "Step marked as completed. Great job!"
    when "skipped"
      @step.update(status: :skipped)
      flash[:notice] = "Step skipped."
    end
    
    redirect_to credit_improvement_path(@plan)
  end
  
  def refresh_plan
    if @plan.needs_update?
      @plan.update_plan!
      flash[:notice] = "Your credit improvement plan has been updated with new recommendations."
    else
      flash[:notice] = "Your plan is already up to date."
    end
    
    redirect_to credit_improvement_path(@plan)
  end
  
  private
  
  def set_credit_improvement_plan
    @plan = CreditImprovementPlan.find(params[:id])
    
    # Ensure the plan belongs to the current user
    unless @plan.user == current_user
      redirect_to credit_improvement_index_path, alert: "You don't have access to this plan."
    end
  end
end
