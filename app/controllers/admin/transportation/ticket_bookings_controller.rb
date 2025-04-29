module Admin
  module Transportation
    class TicketBookingsController < Admin::BaseController
      before_action :set_ticket_booking, only: [:show, :edit, :update, :destroy]
      
      def index
        @page_title = "Ticket Bookings"
        @ticket_bookings = TicketBooking.includes(:user, :route, :transport_company).order(created_at: :desc)
        
        # Filter by status if provided
        if params[:status].present?
          @ticket_bookings = @ticket_bookings.where(status: params[:status])
        end
        
        # Filter by transport type if provided
        if params[:transport_type].present?
          @ticket_bookings = @ticket_bookings.where(transport_type: params[:transport_type])
        end
        
        # Filter by transport company if provided
        if params[:transport_company_id].present?
          @ticket_bookings = @ticket_bookings.where(transport_company_id: params[:transport_company_id])
        end
        
        # Paginate results
        @pagy, @ticket_bookings = pagy(@ticket_bookings, items: 20)
      end
      
      def show
        @page_title = "Ticket Booking ##{@ticket_booking.booking_reference}"
      end
      
      def edit
        @page_title = "Edit Ticket Booking ##{@ticket_booking.booking_reference}"
      end
      
      def update
        if @ticket_booking.update(ticket_booking_params)
          flash[:notice] = "Ticket booking was successfully updated."
          redirect_to admin_transportation_ticket_booking_path(@ticket_booking)
        else
          @page_title = "Edit Ticket Booking ##{@ticket_booking.booking_reference}"
          render :edit
        end
      end
      
      def destroy
        @ticket_booking.destroy
        flash[:notice] = "Ticket booking was successfully deleted."
        redirect_to admin_transportation_ticket_bookings_path
      end
      
      private
      
      def set_ticket_booking
        @ticket_booking = TicketBooking.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        flash[:alert] = "Ticket booking not found."
        redirect_to admin_transportation_ticket_bookings_path
      end
      
      def ticket_booking_params
        params.require(:ticket_booking).permit(
          :status,
          :passengers,
          :price,
          :payment_status,
          :seat_numbers,
          :notes
        )
      end
    end
  end
end
