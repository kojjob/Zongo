module Transportation
  class RidesController < ApplicationController
    before_action :authenticate_user!, except: [:index]

    def index
      @page_title = "Book a Ride"
      @recent_locations = current_user.recent_locations.order(created_at: :desc).limit(5) if user_signed_in?
    end

    def search
      @origin = params[:origin]
      @destination = params[:destination]
      @date = params[:date]
      @time = params[:time]
      
      # In a real implementation, this would search for available rides
      # For now, we'll just create some sample rides
      @rides = sample_rides(@origin, @destination)
      
      respond_to do |format|
        format.turbo_stream
        format.html { render :index }
      end
    end

    def book
      # This would handle the booking of a ride
      @ride_id = params[:ride_id]
      @payment_method = params[:payment_method]
      
      # In a real implementation, this would create a booking
      flash[:notice] = "Your ride has been booked successfully!"
      
      respond_to do |format|
        format.html { redirect_to transportation_my_rides_path }
        format.turbo_stream
      end
    end

    def my_rides
      @page_title = "My Rides"
      # In a real implementation, this would fetch the user's rides
      @upcoming_rides = []
      @past_rides = []
    end

    private

    def sample_rides(origin, destination)
      # Generate some sample rides for demonstration
      [
        {
          id: 1,
          driver_name: "John Doe",
          driver_rating: 4.8,
          vehicle: "Toyota Camry",
          vehicle_color: "Black",
          license_plate: "GH-1234-20",
          price: 25.00,
          currency: "GHS",
          pickup_time: 15.minutes.from_now,
          dropoff_time: 45.minutes.from_now,
          distance: "5.2 km",
          duration: "30 min",
          ride_type: "Standard"
        },
        {
          id: 2,
          driver_name: "Jane Smith",
          driver_rating: 4.9,
          vehicle: "Honda Accord",
          vehicle_color: "White",
          license_plate: "GH-5678-21",
          price: 35.00,
          currency: "GHS",
          pickup_time: 10.minutes.from_now,
          dropoff_time: 35.minutes.from_now,
          distance: "5.2 km",
          duration: "25 min",
          ride_type: "Premium"
        },
        {
          id: 3,
          driver_name: "Samuel Johnson",
          driver_rating: 4.7,
          vehicle: "Hyundai Sonata",
          vehicle_color: "Silver",
          license_plate: "GH-9012-22",
          price: 20.00,
          currency: "GHS",
          pickup_time: 20.minutes.from_now,
          dropoff_time: 55.minutes.from_now,
          distance: "5.2 km",
          duration: "35 min",
          ride_type: "Economy"
        }
      ]
    end
  end
end
