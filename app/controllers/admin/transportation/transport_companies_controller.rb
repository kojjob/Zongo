module Admin
  module Transportation
    class TransportCompaniesController < Admin::AdminController
      before_action :set_transport_company, only: [:show, :edit, :update, :destroy]
      
      def index
        @page_title = "Transport Companies"
        @transport_companies = TransportCompany.all.order(:name)
        
        # Paginate results
        @pagy, @transport_companies = pagy(@transport_companies, items: 20)
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
          redirect_to admin_transportation_transport_company_path(@transport_company)
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
          redirect_to admin_transportation_transport_company_path(@transport_company)
        else
          @page_title = "Edit #{@transport_company.name}"
          render :edit
        end
      end
      
      def destroy
        if @transport_company.ticket_bookings.exists?
          flash[:alert] = "Cannot delete transport company with existing bookings."
          redirect_to admin_transportation_transport_company_path(@transport_company)
        else
          @transport_company.destroy
          flash[:notice] = "Transport company was successfully deleted."
          redirect_to admin_transportation_transport_companies_path
        end
      end
      
      private
      
      def set_transport_company
        @transport_company = TransportCompany.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        flash[:alert] = "Transport company not found."
        redirect_to admin_transportation_transport_companies_path
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
    end
  end
end
