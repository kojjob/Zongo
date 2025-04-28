class TransportationController < ApplicationController
  before_action :authenticate_user!, except: [:index]

  def index
    @page_title = "Transportation Services"
  end

  def rides
    @page_title = "Book a Ride"
    @recent_locations = current_user.recent_locations.order(created_at: :desc).limit(5) if user_signed_in?
  end

  def tickets
    @page_title = "Travel Tickets"
    @upcoming_trips = current_user.bookings.upcoming.order(departure_date: :asc).limit(5) if user_signed_in?
    @popular_routes = Route.popular.limit(5)
  end

  def search_rides
    # This would handle the AJAX search for rides
    @origin = params[:origin]
    @destination = params[:destination]
    @date = params[:date]
    
    # In a real implementation, this would search for available rides
    @rides = []
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to rides_path }
    end
  end

  def search_tickets
    # This would handle the AJAX search for tickets
    @origin = params[:origin]
    @destination = params[:destination]
    @date = params[:date]
    @passengers = params[:passengers] || 1
    
    # In a real implementation, this would search for available tickets
    @tickets = []
    
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to tickets_path }
    end
  end
end
