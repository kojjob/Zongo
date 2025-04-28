module Transportation
  class TransportCompaniesController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin
    before_action :set_transport_company, only: [:show, :edit, :update, :destroy]
    
    def index
      @page_title = "Transport Companies"
      @transport_companies = TransportCompany.all.order(:name)
    end
    
    def show
      @page_title = @transport_company.name
      @routes = @transport_company.routes.order(:origin, :destination)
    end
    
    def new
      @page_title = "New Transport Company"
      @transport_company = TransportCompany.new
    end
    
    def create
      @transport_company = TransportCompany.new(transport_company_params)
      
      if @transport_company.save
        flash[:notice] = "Transport company was successfully created."
        redirect_to transportation_transport_company_path(@transport_company)
      else
        @page_title = "New Transport Company"
        render :new
      end
    end
    
    def edit
      @page_title = "Edit #{@transport_company.name}"
    end
    
    def update
      if @transport_company.update(transport_company_params)
        flash[:notice] = "Transport company was successfully updated."
        redirect_to transportation_transport_company_path(@transport_company)
      else
        @page_title = "Edit #{@transport_company.name}"
        render :edit
      end
    end
    
    def destroy
      if @transport_company.ticket_bookings.exists?
        flash[:alert] = "Cannot delete transport company with existing bookings."
        redirect_to transportation_transport_company_path(@transport_company)
      else
        @transport_company.destroy
        flash[:notice] = "Transport company was successfully deleted."
        redirect_to transportation_transport_companies_path
      end
    end
    
    private
    
    def set_transport_company
      @transport_company = TransportCompany.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      flash[:alert] = "Transport company not found."
      redirect_to transportation_transport_companies_path
    end
    
    def transport_company_params
      params.require(:transport_company).permit(
        :name, 
        :transport_type, 
        :logo_url, 
        :website, 
        :phone, 
        :email, 
        :description, 
        :active,
        amenities: []
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
