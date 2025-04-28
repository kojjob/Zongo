module Transportation
  class RoutesController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin
    before_action :set_route, only: [:show, :edit, :update, :destroy]
    before_action :set_transport_companies, only: [:new, :create, :edit, :update]
    
    def index
      @page_title = "Routes"
      @routes = Route.includes(:transport_company).order(:origin, :destination)
    end
    
    def show
      @page_title = "#{@route.origin} to #{@route.destination}"
      @ticket_bookings = @route.ticket_bookings.includes(:user).order(departure_time: :desc).limit(10)
    end
    
    def new
      @page_title = "New Route"
      @route = Route.new
    end
    
    def create
      @route = Route.new(route_params)
      
      if @route.save
        flash[:notice] = "Route was successfully created."
        redirect_to transportation_route_path(@route)
      else
        @page_title = "New Route"
        render :new
      end
    end
    
    def edit
      @page_title = "Edit Route"
    end
    
    def update
      if @route.update(route_params)
        flash[:notice] = "Route was successfully updated."
        redirect_to transportation_route_path(@route)
      else
        @page_title = "Edit Route"
        render :edit
      end
    end
    
    def destroy
      if @route.ticket_bookings.exists?
        flash[:alert] = "Cannot delete route with existing bookings."
        redirect_to transportation_route_path(@route)
      else
        @route.destroy
        flash[:notice] = "Route was successfully deleted."
        redirect_to transportation_routes_path
      end
    end
    
    private
    
    def set_route
      @route = Route.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:alert] = "Route not found."
      redirect_to transportation_routes_path
    end
    
    def set_transport_companies
      @transport_companies = TransportCompany.active.order(:name)
    end
    
    def route_params
      params.require(:route).permit(
        :origin, 
        :destination, 
        :distance, 
        :transport_company_id, 
        :duration_minutes, 
        :base_price, 
        :currency, 
        :popular, 
        :active, 
        :transport_type,
        amenities: [],
        schedule: {}
      )
    end
    
    def require_admin
      unless current_user.admin?
        flash[:alert] = "You are not authorized to access this page."
        redirect_to root_path
      end
    end
  end
end
