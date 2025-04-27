module Admin
  class ReviewsController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin
    before_action :set_review, only: [:show, :edit, :update, :destroy, :approve, :reject]
    layout "admin"
    
    def index
      reviews_query = Review.all.includes(:user, :product)
      
      # Apply filters
      if params[:product_id].present?
        reviews_query = reviews_query.where(product_id: params[:product_id])
      end
      
      if params[:user_id].present?
        reviews_query = reviews_query.where(user_id: params[:user_id])
      end
      
      if params[:approved].present?
        reviews_query = reviews_query.where(approved: params[:approved] == "true")
      end
      
      if params[:rating].present?
        reviews_query = reviews_query.where(rating: params[:rating])
      end
      
      if params[:search].present?
        reviews_query = reviews_query.where("comment ILIKE ?", "%#{params[:search]}%")
      end
      
      # Apply sorting
      case params[:sort]
      when "newest"
        reviews_query = reviews_query.order(created_at: :desc)
      when "oldest"
        reviews_query = reviews_query.order(created_at: :asc)
      when "rating_high"
        reviews_query = reviews_query.order(rating: :desc)
      when "rating_low"
        reviews_query = reviews_query.order(rating: :asc)
      else
        reviews_query = reviews_query.order(created_at: :desc)
      end
      
      @pagy, @reviews = pagy(reviews_query, items: 20)
    end
    
    def show
    end
    
    def edit
    end
    
    def update
      if @review.update(review_params)
        redirect_to admin_review_path(@review), notice: "Review was successfully updated."
      else
        render :edit
      end
    end
    
    def destroy
      @review.destroy
      redirect_to admin_reviews_path, notice: "Review was successfully deleted."
    end
    
    def approve
      @review.update(approved: true, approved_at: Time.current)
      redirect_to admin_review_path(@review), notice: "Review has been approved."
    end
    
    def reject
      @review.update(approved: false, approved_at: nil)
      redirect_to admin_review_path(@review), notice: "Review has been rejected."
    end
    
    private
    
    def set_review
      @review = Review.find(params[:id])
    end
    
    def review_params
      params.require(:review).permit(:rating, :comment, :approved, :admin_comment)
    end
  end
end
