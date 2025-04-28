class EducationController < ApplicationController
  before_action :authenticate_user!, except: [:index]

  def index
    @page_title = "Education Services"
    @featured_schools = School.featured.limit(6)
    @featured_resources = LearningResource.featured.limit(3)
  end

  def school_fees
    @page_title = "School Fees Payment"
    @recent_payments = current_user.school_fee_payments.order(created_at: :desc).limit(5) if user_signed_in?
    @popular_schools = School.popular.limit(10)
  end

  def resources
    @page_title = "Learning Resources"
    @categories = ResourceCategory.all
    @featured_resources = LearningResource.featured.limit(6)
    @recent_resources = LearningResource.recent.limit(8)
  end

  def search_schools
    @query = params[:query]
    @schools = School.where("name ILIKE ?", "%#{@query}%").limit(10)
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to education_school_fees_path }
    end
  end

  def search_resources
    @query = params[:query]
    @category_id = params[:category_id]
    
    @resources = LearningResource.all
    @resources = @resources.where("title ILIKE ? OR description ILIKE ?", "%#{@query}%", "%#{@query}%") if @query.present?
    @resources = @resources.where(resource_category_id: @category_id) if @category_id.present?
    @resources = @resources.limit(20)
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to education_resources_path }
    end
  end

  def pay_fees
    @school_id = params[:school_id]
    @student_id = params[:student_id]
    @amount = params[:amount]
    @payment_method = params[:payment_method]
    
    # In a real implementation, this would create a payment
    flash[:notice] = "School fees payment successful!"
    
    respond_to do |format|
      format.html { redirect_to education_school_fees_path }
      format.turbo_stream
    end
  end
end
