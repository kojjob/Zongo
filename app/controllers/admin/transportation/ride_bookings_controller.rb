module Admin
  module Transportation
    class RideBookingsController < Admin::BaseController
      before_action :set_ride_booking, only: [:show, :edit, :update, :destroy]
      
      def index
        @page_title = "Ride Bookings"
        @ride_bookings = RideBooking.includes(:user).order(created_at: :desc)
        
        # Filter by status if provided
        if params[:status].present?
          @ride_bookings = @ride_bookings.where(status: params[:status])
        end
        
        # Paginate results
        @pagy, @ride_bookings = pagy(@ride_bookings, items: 20)
      end
      
      def show
        @page_title = "Ride Booking ##{@ride_booking.id}"
      end
      
      def edit
        @page_title = "Edit Ride Booking ##{@ride_booking.id}"
      end
      
      def update
        if @ride_booking.update(ride_booking_params)
          flash[:notice] = "Ride booking was successfully updated."
          redirect_to admin_transportation_ride_booking_path(@ride_booking)
        else
          @page_title = "Edit Ride Booking ##{@ride_booking.id}"
          render :edit
        end
      end
      
      def destroy
        @ride_booking.destroy
        flash[:notice] = "Ride booking was successfully deleted."
        redirect_to admin_transportation_ride_bookings_path
      end
      
      private
      
      def set_ride_booking
        @ride_booking = RideBooking.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        flash[:alert] = "Ride booking not found."
        redirect_to admin_transportation_ride_bookings_path
      end
      
      def ride_booking_params
        params.require(:ride_booking).permit(
          :status,
          :driver_name,
          :driver_phone,
          :vehicle_model,
          :vehicle_color,
          :license_plate,
          :price,
          :payment_status,
          :notes
        )
      end
    end
  end
end
