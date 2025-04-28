module Transportation
  class AnalyticsController < ApplicationController
    layout 'transportation_admin'
    before_action :authenticate_user!
    before_action :require_admin

    def index
      @page_title = "Transportation Analytics"

      # In a real implementation, we would fetch actual data from the database
      # For now, we'll use sample data

      # Ride statistics
      @total_rides = 1250
      @completed_rides = 980
      @cancelled_rides = 120
      @active_rides = 150

      # Ticket statistics
      @total_tickets = 2350
      @completed_tickets = 1850
      @cancelled_tickets = 200
      @active_tickets = 300

      # Revenue statistics
      @total_revenue = 45000
      @ride_revenue = 15000
      @ticket_revenue = 30000

      # Popular routes
      @popular_routes = [
        { origin: "Accra", destination: "Kumasi", count: 450, revenue: 12500 },
        { origin: "Accra", destination: "Cape Coast", count: 320, revenue: 8500 },
        { origin: "Kumasi", destination: "Tamale", count: 280, revenue: 7500 },
        { origin: "Accra", destination: "Takoradi", count: 250, revenue: 6500 },
        { origin: "Kumasi", destination: "Accra", count: 220, revenue: 6000 }
      ]

      # Monthly statistics
      @monthly_stats = [
        { month: "January", rides: 95, tickets: 180, revenue: 3500 },
        { month: "February", rides: 110, tickets: 210, revenue: 4200 },
        { month: "March", rides: 125, tickets: 240, revenue: 4800 },
        { month: "April", rides: 140, tickets: 270, revenue: 5400 },
        { month: "May", rides: 155, tickets: 300, revenue: 6000 },
        { month: "June", rides: 170, tickets: 330, revenue: 6600 }
      ]
    end

    private

    def require_admin
      unless current_user.admin?
        flash[:alert] = "You are not authorized to access this page."
        redirect_to transportation_path
      end
    end
  end
end
