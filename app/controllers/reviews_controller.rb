class ReviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_product
  before_action :set_review, only: [:edit, :update, :destroy]
  before_action :check_purchase, only: [:new, :create]
  
  def new
    @review = @product.reviews.new
  end
  
  def create
    @review = @product.reviews.new(review_params)
    @review.user = current_user
    
    if @review.save
      redirect_to product_path(@product), notice: "Review submitted successfully. It will be visible after approval."
    else
      render :new
    end
  end
  
  def edit
    # Review is set in before_action
  end
  
  def update
    if @review.update(review_params)
      redirect_to product_path(@product), notice: "Review updated successfully."
    else
      render :edit
    end
  end
  
  def destroy
    @review.destroy
    redirect_to product_path(@product), notice: "Review deleted successfully."
  end
  
  private
  
  def set_product
    @product = Product.find(params[:product_id])
  end
  
  def set_review
    @review = current_user.reviews.find(params[:id])
  end
  
  def review_params
    params.require(:review).permit(:rating, :comment)
  end
  
  def check_purchase
    unless current_user.orders.completed.joins(:order_items).where(order_items: { product_id: @product.id }).exists?
      redirect_to product_path(@product), alert: "You must purchase this product before leaving a review."
    end
  end
end
