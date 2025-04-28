module Transportation
  class RidesController < ApplicationController
    before_action :authenticate_user!, except: [:index]
    before_action :set_ride_booking, only: [:show, :edit, :update, :cancel]

    def index
      @page_title = "Book a Ride"
      @recent_locations = current_user.recent_locations.order(created_at: :desc).limit(5) if user_signed_in?
    end

    def search
      @origin = params[:origin]
      @destination = params[:destination]
      @date = params[:date]
      @time = params[:time]

      # Save the search location to recent locations if user is signed in
      if user_signed_in? && @origin.present?
        save_recent_location(@origin, "origin")
      end

      if user_signed_in? && @destination.present?
        save_recent_location(@destination, "destination")
      end

      # In a real implementation, this would search for available rides
      # For now, we'll just create some sample rides
      @rides = sample_rides(@origin, @destination)

      respond_to do |format|
        format.turbo_stream
        format.html { render :index }
      end
    end

    def book
      @ride_id = params[:ride_id]
      @payment_method = params[:payment_method]
      @origin = params[:origin]
      @destination = params[:destination]
      @pickup_time = parse_datetime(params[:date], params[:time])

      # Create a new ride booking
      @ride_booking = current_user.ride_bookings.new(
        origin_address: @origin,
        destination_address: @destination,
        pickup_time: @pickup_time,
        ride_type: params[:ride_type] || 'standard',
        price: params[:price] || calculate_ride_price(@origin, @destination, params[:ride_type]),
        status: :pending,
        payment_method: @payment_method
      )

      # Set driver and vehicle details (in a real app, this would be assigned by the system)
      @ride_booking.driver_name = ["John Doe", "Jane Smith", "Michael Brown", "Sarah Wilson"].sample
      @ride_booking.vehicle_model = ["Toyota Camry", "Honda Accord", "Ford Focus", "Tesla Model 3"].sample
      @ride_booking.vehicle_color = ["Black", "White", "Silver", "Blue"].sample
      @ride_booking.license_plate = "#{('A'..'Z').to_a.sample(2).join}-#{rand(1000..9999)}"

      if @ride_booking.save
        # In a real implementation, this would process payment and assign a driver
        flash[:notice] = "Your ride has been booked successfully!"

        respond_to do |format|
          format.html { redirect_to transportation_my_rides_path }
          format.turbo_stream
        end
      else
        flash[:alert] = "Failed to book your ride. Please try again."

        respond_to do |format|
          format.html { redirect_to transportation_rides_path }
          format.turbo_stream { render turbo_stream: turbo_stream.replace("booking_form", partial: "transportation/rides/booking_form", locals: { error: @ride_booking.errors.full_messages.join(", ") }) }
        end
      end
    end

    def show
      @page_title = "Ride Details"
    end

    def cancel
      if @ride_booking.pending? || @ride_booking.confirmed?
        @ride_booking.update(status: :cancelled)
        flash[:notice] = "Your ride has been cancelled."
      else
        flash[:alert] = "This ride cannot be cancelled."
      end

      redirect_to transportation_my_rides_path
    end

    def my_rides
      @page_title = "My Rides"

      # Fetch the user's rides from the database
      @upcoming_rides = current_user.ride_bookings
                                   .where(status: [:pending, :confirmed])
                                   .where("pickup_time > ?", Time.current)
                                   .order(pickup_time: :asc)

      @past_rides = current_user.ride_bookings
                               .where(status: [:completed, :cancelled])
                               .or(current_user.ride_bookings.where("pickup_time < ?", Time.current))
                               .order(pickup_time: :desc)
                               .limit(10)

      # If no rides exist yet, use sample data
      if @upcoming_rides.empty? && @past_rides.empty?
        @upcoming_rides = sample_upcoming_rides
        @past_rides = sample_past_rides
      end
    end

    private

    def set_ride_booking
      @ride_booking = current_user.ride_bookings.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:alert] = "Ride not found."
      redirect_to transportation_my_rides_path
    end

    def save_recent_location(address, location_type)
      # Check if this location already exists for the user
      existing_location = current_user.recent_locations.find_by(address: address)

      if existing_location
        # Update the timestamp to move it to the top of the list
        existing_location.touch
      else
        # Create a new recent location
        current_user.recent_locations.create(
          name: "#{location_type.capitalize} - #{address.split(',').first}",
          address: address,
          # In a real app, we would geocode the address to get latitude and longitude
          latitude: rand(5.5..6.0),
          longitude: rand(-0.3..0.3)
        )

        # Limit the number of recent locations
        if current_user.recent_locations.count > 10
          oldest_location = current_user.recent_locations.order(updated_at: :asc).first
          oldest_location.destroy if oldest_location
        end
      end
    end

    def parse_datetime(date_str, time_str)
      return Time.current + 15.minutes if date_str.blank? || time_str.blank?

      begin
        date = Date.parse(date_str)
        time = Time.parse(time_str)

        DateTime.new(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.min,
          0,
          Time.zone.formatted_offset
        )
      rescue ArgumentError
        Time.current + 15.minutes
      end
    end

    def calculate_ride_price(origin, destination, ride_type)
      # In a real app, this would calculate the price based on distance, time, and ride type
      # For now, we'll just return a random price based on the ride type
      base_price = case ride_type.to_s.downcase
                   when 'economy'
                     20.0
                   when 'standard'
                     30.0
                   when 'premium'
                     45.0
                   else
                     25.0
                   end

      # Add some randomness to the price
      (base_price + rand(5..15)).round(2)
    end

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

    def sample_upcoming_rides
      [
        {
          id: 101,
          driver_name: "Michael Brown",
          driver_rating: 4.7,
          vehicle: "Toyota Corolla",
          vehicle_color: "Blue",
          license_plate: "GH-3456-23",
          price: 30.00,
          currency: "GHS",
          pickup_time: 2.hours.from_now,
          distance: "7.5 km",
          duration: "35 min",
          ride_type: "Standard"
        },
        {
          id: 102,
          driver_name: "Sarah Wilson",
          driver_rating: 4.9,
          vehicle: "Honda Civic",
          vehicle_color: "Red",
          license_plate: "GH-7890-24",
          price: 45.00,
          currency: "GHS",
          pickup_time: 1.day.from_now,
          distance: "12.3 km",
          duration: "50 min",
          ride_type: "Premium"
        }
      ]
    end

    def sample_past_rides
      [
        {
          id: 201,
          driver_name: "David Lee",
          driver_rating: 4.6,
          vehicle: "Toyota Prius",
          vehicle_color: "Silver",
          license_plate: "GH-2345-19",
          price: 28.50,
          currency: "GHS",
          pickup_time: 2.days.ago,
          distance: "6.8 km",
          duration: "32 min",
          ride_type: "Economy"
        },
        {
          id: 202,
          driver_name: "Emily Chen",
          driver_rating: 4.8,
          vehicle: "Nissan Altima",
          vehicle_color: "Black",
          license_plate: "GH-6789-20",
          price: 38.75,
          currency: "GHS",
          pickup_time: 5.days.ago,
          distance: "9.2 km",
          duration: "40 min",
          ride_type: "Standard"
        },
        {
          id: 203,
          driver_name: "Robert Taylor",
          driver_rating: 4.9,
          vehicle: "Mercedes-Benz C-Class",
          vehicle_color: "White",
          license_plate: "GH-0123-21",
          price: 55.00,
          currency: "GHS",
          pickup_time: 1.week.ago,
          distance: "15.5 km",
          duration: "55 min",
          ride_type: "Premium"
        }
      ]
    end
  end
end
