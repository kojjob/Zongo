module Transportation
  class TicketsController < ApplicationController
    before_action :authenticate_user!, except: [:index]

    def index
      @page_title = "Travel Tickets"
      @popular_routes = sample_popular_routes
    end

    def search
      @origin = params[:origin]
      @destination = params[:destination]
      @date = params[:date]
      @passengers = params[:passengers] || 1
      @transport_type = params[:transport_type] || 'all'
      
      # In a real implementation, this would search for available tickets
      @tickets = sample_tickets(@origin, @destination, @transport_type)
      
      respond_to do |format|
        format.turbo_stream
        format.html { render :index }
      end
    end

    def book
      # This would handle the booking of a ticket
      @ticket_id = params[:ticket_id]
      @passengers = params[:passengers] || 1
      @payment_method = params[:payment_method]
      
      # In a real implementation, this would create a booking
      flash[:notice] = "Your ticket has been booked successfully!"
      
      respond_to do |format|
        format.html { redirect_to transportation_my_tickets_path }
        format.turbo_stream
      end
    end

    def my_tickets
      @page_title = "My Tickets"
      # In a real implementation, this would fetch the user's tickets
      @upcoming_tickets = []
      @past_tickets = []
    end

    private

    def sample_popular_routes
      [
        { from: "Accra", to: "Kumasi", price: 120.00, transport_type: "Bus" },
        { from: "Accra", to: "Tamale", price: 180.00, transport_type: "Bus" },
        { from: "Accra", to: "Cape Coast", price: 80.00, transport_type: "Bus" },
        { from: "Kumasi", to: "Tamale", price: 150.00, transport_type: "Bus" },
        { from: "Accra", to: "Takoradi", price: 100.00, transport_type: "Bus" }
      ]
    end

    def sample_tickets(origin, destination, transport_type)
      # Generate some sample tickets for demonstration
      [
        {
          id: 1,
          company: "Ghana Express",
          transport_type: "Bus",
          departure_time: 2.hours.from_now,
          arrival_time: 6.hours.from_now,
          duration: "4h 0m",
          price: 120.00,
          currency: "GHS",
          available_seats: 15,
          amenities: ["Air Conditioning", "WiFi", "Restroom"]
        },
        {
          id: 2,
          company: "Metro Mass Transit",
          transport_type: "Bus",
          departure_time: 3.hours.from_now,
          arrival_time: 7.5.hours.from_now,
          duration: "4h 30m",
          price: 100.00,
          currency: "GHS",
          available_seats: 25,
          amenities: ["Air Conditioning"]
        },
        {
          id: 3,
          company: "VIP Transport",
          transport_type: "Bus",
          departure_time: 4.hours.from_now,
          arrival_time: 7.hours.from_now,
          duration: "3h 0m",
          price: 150.00,
          currency: "GHS",
          available_seats: 10,
          amenities: ["Air Conditioning", "WiFi", "Restroom", "Refreshments"]
        },
        {
          id: 4,
          company: "Ghana Railways",
          transport_type: "Train",
          departure_time: 5.hours.from_now,
          arrival_time: 8.hours.from_now,
          duration: "3h 0m",
          price: 80.00,
          currency: "GHS",
          available_seats: 50,
          amenities: ["Air Conditioning", "Cafeteria"]
        }
      ].select { |ticket| transport_type == 'all' || ticket[:transport_type].downcase == transport_type.downcase }
    end
  end
end
