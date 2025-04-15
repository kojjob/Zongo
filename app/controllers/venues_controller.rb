class VenuesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_venue, only: [ :show, :edit, :update, :destroy ]

  # GET /venues
  def index
    @venues = Venue.all.order(:name)
  end

  # GET /venues/:id
  def show
    @upcoming_events = @venue.events.upcoming.order(start_time: :asc).limit(5)
  end

  # GET /venues/new
  def new
    @venue = Venue.new
  end

  # POST /venues
  def create
    @venue = Venue.new(venue_params)

    if @venue.save
      redirect_to @venue, notice: "Venue created successfully!"
    else
      render :new
    end
  end

  # GET /venues/:id/edit
  def edit
  end

  # PATCH/PUT /venues/:id
  def update
    if @venue.update(venue_params)
      redirect_to @venue, notice: "Venue updated successfully!"
    else
      render :edit
    end
  end

  # DELETE /venues/:id
  def destroy
    @venue.destroy
    redirect_to venues_path, notice: "Venue deleted successfully!"
  end

  private

  def set_venue
    @venue = Venue.find(params[:id])
  end

  def venue_params
    params.require(:venue).permit(
      :name, :address, :city, :region, :state, :country, :postal_code,
      :latitude, :longitude, :description, :website, :phone, :capacity,
      :user_id, facilities: {}
    )
  end
end
