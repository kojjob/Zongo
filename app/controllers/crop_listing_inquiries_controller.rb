class CropListingInquiriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_inquiry, only: [:show, :respond, :accept, :reject]
  before_action :ensure_authorized, only: [:show, :respond, :accept, :reject]
  
  def create
    @crop_listing = CropListing.find(params[:crop_listing_id])
    @inquiry = CropListingInquiry.new(inquiry_params)
    @inquiry.user = current_user
    @inquiry.crop_listing = @crop_listing
    
    if @inquiry.save
      redirect_to @crop_listing, notice: 'Your inquiry has been sent to the seller.'
    else
      redirect_to @crop_listing, alert: 'Failed to send inquiry. Please try again.'
    end
  end
  
  def show
    # Mark as read if viewing as the listing owner
    if current_user.id == @inquiry.crop_listing.user_id && !@inquiry.read
      @inquiry.mark_as_read!
    end
    
    @crop_listing = @inquiry.crop_listing
  end
  
  def my_inquiries
    @sent_inquiries = current_user.crop_listing_inquiries.order(created_at: :desc)
    @received_inquiries = CropListingInquiry.joins(:crop_listing)
                                           .where(crop_listings: { user_id: current_user.id })
                                           .order(created_at: :desc)
  end
  
  def respond
    if @inquiry.update(response_params)
      @inquiry.respond!(params[:crop_listing_inquiry][:response])
      redirect_to @inquiry.crop_listing, notice: 'Your response has been sent.'
    else
      redirect_to @inquiry.crop_listing, alert: 'Failed to send response. Please try again.'
    end
  end
  
  def accept
    @inquiry.accept!
    redirect_to @inquiry.crop_listing, notice: 'You have accepted this inquiry.'
  end
  
  def reject
    @inquiry.reject!
    redirect_to @inquiry.crop_listing, notice: 'You have rejected this inquiry.'
  end
  
  private
  
  def set_inquiry
    @inquiry = CropListingInquiry.find(params[:id])
  end
  
  def ensure_authorized
    # Check if user is either the inquiry sender or the listing owner
    unless current_user.id == @inquiry.user_id || current_user.id == @inquiry.crop_listing.user_id
      redirect_to root_path, alert: 'You are not authorized to view this inquiry.'
    end
  end
  
  def inquiry_params
    params.require(:crop_listing_inquiry).permit(:message, :quantity, :offered_price)
  end
  
  def response_params
    params.require(:crop_listing_inquiry).permit(:response)
  end
end
