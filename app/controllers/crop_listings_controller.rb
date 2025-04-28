class CropListingsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_crop_listing, only: [:show, :edit, :update, :destroy, :mark_as_sold, :renew]
  before_action :ensure_owner, only: [:edit, :update, :destroy, :mark_as_sold, :renew]
  
  def index
    redirect_to marketplace_agriculture_path
  end
  
  def show
    @related_listings = CropListing.active
                                  .where(crop_id: @crop_listing.crop_id)
                                  .where.not(id: @crop_listing.id)
                                  .limit(4)
    
    # Check if the current user is the owner
    @is_owner = user_signed_in? && current_user.id == @crop_listing.user_id
    
    # Get inquiries if user is the owner
    if @is_owner
      @inquiries = @crop_listing.crop_listing_inquiries.order(created_at: :desc)
    end
    
    # Initialize a new inquiry for the form
    @inquiry = CropListingInquiry.new
  end
  
  def new
    @crop_listing = CropListing.new
    @crops = Crop.all.order(:name)
    @regions = Region.all.order(:name)
  end
  
  def create
    @crop_listing = CropListing.new(crop_listing_params)
    @crop_listing.user = current_user
    
    if @crop_listing.save
      redirect_to @crop_listing, notice: 'Your listing was successfully created.'
    else
      @crops = Crop.all.order(:name)
      @regions = Region.all.order(:name)
      render :new
    end
  end
  
  def edit
    @crops = Crop.all.order(:name)
    @regions = Region.all.order(:name)
  end
  
  def update
    if @crop_listing.update(crop_listing_params)
      redirect_to @crop_listing, notice: 'Your listing was successfully updated.'
    else
      @crops = Crop.all.order(:name)
      @regions = Region.all.order(:name)
      render :edit
    end
  end
  
  def destroy
    @crop_listing.destroy
    redirect_to my_listings_crop_listings_path, notice: 'Your listing was successfully deleted.'
  end
  
  def my_listings
    @active_listings = current_user.crop_listings.active.order(created_at: :desc)
    @sold_listings = current_user.crop_listings.sold.order(created_at: :desc)
    @expired_listings = current_user.crop_listings.expired.order(created_at: :desc)
  end
  
  def mark_as_sold
    @crop_listing.mark_as_sold!
    redirect_to @crop_listing, notice: 'Your listing has been marked as sold.'
  end
  
  def renew
    @crop_listing.renew!
    redirect_to @crop_listing, notice: 'Your listing has been renewed for 30 days.'
  end
  
  private
  
  def set_crop_listing
    @crop_listing = CropListing.find(params[:id])
  end
  
  def ensure_owner
    unless current_user.id == @crop_listing.user_id
      redirect_to @crop_listing, alert: 'You are not authorized to perform this action.'
    end
  end
  
  def crop_listing_params
    params.require(:crop_listing).permit(
      :crop_id, :region_id, :title, :description, :price, :quantity, 
      :unit, :listing_type, :negotiable, :location, :terms, images: []
    )
  end
end
