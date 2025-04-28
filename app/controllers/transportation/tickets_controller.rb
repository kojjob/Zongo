module Transportation
  class TicketsController < ApplicationController
    before_action :authenticate_user!, except: [:index]
    before_action :set_ticket_booking, only: [:show, :cancel]

    def index
      @page_title = "Travel Tickets"

      # Get popular routes from the database
      @popular_routes = Route.popular.limit(5)

      # If no routes exist yet, use sample data
      if @popular_routes.empty?
        @popular_routes = sample_popular_routes
      end
    end

    def search
      @origin = params[:origin]
      @destination = params[:destination]
      @date = params[:date]
      @passengers = params[:passengers] || 1
      @transport_type = params[:transport_type] || 'all'

      # In a real implementation, this would search for available tickets
      # For now, we'll just create some sample tickets
      @tickets = sample_tickets(@origin, @destination, @transport_type)

      respond_to do |format|
        format.turbo_stream
        format.html { render :index }
      end
    end

    def book
      @ticket_id = params[:ticket_id]
      @passengers = params[:passengers].to_i || 1
      @payment_method = params[:payment_method]
      @origin = params[:origin]
      @destination = params[:destination]
      @departure_time = parse_datetime(params[:date], params[:time])
      @transport_type = params[:transport_type] || 'bus'
      @company_name = params[:company_name]
      @price = params[:price].to_f
      @total_price = @price * @passengers

      # Find or create a route
      route = Route.find_or_create_by(
        origin: @origin,
        destination: @destination
      ) do |r|
        r.distance = rand(50..500)
        r.transport_type = @transport_type
      end

      # Create a new ticket booking
      @ticket_booking = current_user.ticket_bookings.new(
        route: route,
        origin: @origin,
        destination: @destination,
        company_name: @company_name,
        transport_type: @transport_type,
        departure_time: @departure_time,
        arrival_time: @departure_time + rand(2..6).hours,
        passengers: @passengers,
        price: @price,
        status: :pending
      )

      # Generate a unique booking reference
      @ticket_booking.booking_reference = "TKT-#{SecureRandom.alphanumeric(8).upcase}"

      if @ticket_booking.save
        # Process payment
        payment_service = Transportation::PaymentService.new(
          user: current_user,
          amount: @total_price,
          payment_method: @payment_method,
          description: "#{@passengers} ticket(s) from #{@origin} to #{@destination}",
          booking: @ticket_booking
        )

        payment_result = payment_service.process_payment

        if payment_result[:success]
          flash[:notice] = "Your ticket has been booked successfully!"

          respond_to do |format|
            format.html { redirect_to transportation_my_tickets_path }
            format.turbo_stream
          end
        else
          # Payment failed, update booking status
          @ticket_booking.update(status: :cancelled)

          flash[:alert] = "Payment failed: #{payment_result[:message]}"

          respond_to do |format|
            format.html { redirect_to transportation_tickets_path }
            format.turbo_stream { render turbo_stream: turbo_stream.replace("booking_form", partial: "transportation/tickets/booking_form", locals: { error: payment_result[:message] }) }
          end
        end
      else
        flash[:alert] = "Failed to book your ticket. Please try again."

        respond_to do |format|
          format.html { redirect_to transportation_tickets_path }
          format.turbo_stream { render turbo_stream: turbo_stream.replace("booking_form", partial: "transportation/tickets/booking_form", locals: { error: @ticket_booking.errors.full_messages.join(", ") }) }
        end
      end
    end

    def show
      @page_title = "Ticket Details"
    end

    def select_seats
      @page_title = "Select Seats"
      @origin = params[:origin]
      @destination = params[:destination]
      @date = params[:date]
      @passengers = params[:passengers] || 1
      @ticket_id = params[:ticket_id]
      @transport_type = params[:transport_type]

      # Find the ticket in the sample data
      @ticket = sample_tickets(@origin, @destination, @transport_type).find { |t| t[:id].to_s == @ticket_id.to_s }

      if @ticket.nil?
        flash[:alert] = "Ticket not found."
        redirect_to transportation_tickets_path
      end
    end

    def cancel
      if @ticket_booking.status == "confirmed"
        @ticket_booking.update(status: :cancelled)
        flash[:notice] = "Your ticket has been cancelled."
      else
        flash[:alert] = "This ticket cannot be cancelled."
      end

      redirect_to transportation_my_tickets_path
    end

    def my_tickets
      @page_title = "My Tickets"

      # Fetch the user's tickets from the database
      @upcoming_tickets = current_user.ticket_bookings
                                     .where(status: [:pending, :confirmed])
                                     .where("departure_time > ?", Time.current)
                                     .order(departure_time: :asc)

      @past_tickets = current_user.ticket_bookings
                                 .where(status: [:completed, :cancelled])
                                 .or(current_user.ticket_bookings.where("departure_time < ?", Time.current))
                                 .order(departure_time: :desc)
                                 .limit(10)

      # If no tickets exist yet, use sample data
      if @upcoming_tickets.empty? && @past_tickets.empty?
        @upcoming_tickets = sample_upcoming_tickets
        @past_tickets = sample_past_tickets
      end
    end

    private

    def set_ticket_booking
      @ticket_booking = current_user.ticket_bookings.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:alert] = "Ticket not found."
      redirect_to transportation_my_tickets_path
    end

    def parse_datetime(date_str, time_str)
      return Time.current + 1.day if date_str.blank? || time_str.blank?

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
        Time.current + 1.day
      end
    end

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

    def sample_upcoming_tickets
      [
        {
          id: 101,
          company: "VIP Transport",
          transport_type: "Bus",
          departure_time: 2.days.from_now,
          arrival_time: 2.days.from_now + 4.hours,
          duration: "4h 0m",
          price: 150.00,
          currency: "GHS",
          amenities: ["Air Conditioning", "WiFi", "Restroom", "Refreshments"]
        },
        {
          id: 102,
          company: "Ghana Railways",
          transport_type: "Train",
          departure_time: 5.days.from_now,
          arrival_time: 5.days.from_now + 3.hours,
          duration: "3h 0m",
          price: 80.00,
          currency: "GHS",
          amenities: ["Air Conditioning", "Cafeteria"]
        }
      ]
    end

    def sample_past_tickets
      [
        {
          id: 201,
          company: "Ghana Express",
          transport_type: "Bus",
          departure_time: 2.weeks.ago,
          arrival_time: 2.weeks.ago + 4.hours,
          duration: "4h 0m",
          price: 120.00,
          currency: "GHS",
          amenities: ["Air Conditioning", "WiFi", "Restroom"]
        },
        {
          id: 202,
          company: "Metro Mass Transit",
          transport_type: "Bus",
          departure_time: 1.month.ago,
          arrival_time: 1.month.ago + 4.5.hours,
          duration: "4h 30m",
          price: 100.00,
          currency: "GHS",
          amenities: ["Air Conditioning"]
        },
        {
          id: 203,
          company: "STC",
          transport_type: "Bus",
          departure_time: 2.months.ago,
          arrival_time: 2.months.ago + 3.5.hours,
          duration: "3h 30m",
          price: 130.00,
          currency: "GHS",
          amenities: ["Air Conditioning", "WiFi", "Restroom"]
        }
      ]
    end
  end
end
