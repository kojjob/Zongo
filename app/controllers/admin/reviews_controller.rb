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

      # Notify the user that their review was approved
      ReviewMailer.review_approved(@review).deliver_later if @review.user.email.present?

      redirect_to admin_review_path(@review), notice: "Review has been approved."
    end

    def reject
      if params[:admin_comment].present?
        @review.update(approved: false, approved_at: nil, admin_comment: params[:admin_comment])

        # Notify the user that their review was rejected with reason
        ReviewMailer.review_rejected(@review).deliver_later if @review.user.email.present?

        redirect_to admin_review_path(@review), notice: "Review has been rejected with feedback."
      else
        @review.update(approved: false, approved_at: nil)
        redirect_to admin_review_path(@review), notice: "Review has been rejected."
      end
    end

    def bulk_approve
      reviews = Review.where(id: params[:review_ids])
      count = 0

      reviews.each do |review|
        if review.update(approved: true, approved_at: Time.current)
          count += 1
          # Notify the user that their review was approved
          ReviewMailer.review_approved(review).deliver_later if review.user.email.present?
        end
      end

      redirect_to admin_reviews_path, notice: "Successfully approved #{count} reviews."
    end

    def bulk_reject
      reviews = Review.where(id: params[:review_ids])
      count = 0

      reviews.each do |review|
        if review.update(approved: false, approved_at: nil)
          count += 1
        end
      end

      redirect_to admin_reviews_path, notice: "Successfully rejected #{count} reviews."
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
