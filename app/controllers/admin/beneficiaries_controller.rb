module Admin
  class BeneficiariesController < BaseController
    before_action :set_beneficiary, only: [:show, :edit, :update, :destroy]

    def index
      @beneficiaries = Beneficiary.all.order(created_at: :desc)

      # Filter by transfer type if provided
      if params[:transfer_type].present?
        @beneficiaries = @beneficiaries.where(transfer_type: params[:transfer_type])
      end

      # Filter by user if provided
      if params[:user_id].present?
        @beneficiaries = @beneficiaries.where(user_id: params[:user_id])
      end

      # Filter by search term if provided
      if params[:search].present?
        @beneficiaries = @beneficiaries.where("name LIKE ? OR account_number LIKE ? OR bank_name LIKE ? OR phone_number LIKE ?",
                                            "%#{params[:search]}%",
                                            "%#{params[:search]}%",
                                            "%#{params[:search]}%",
                                            "%#{params[:search]}%")
      end

      # Paginate results
      @pagy, @beneficiaries = pagy(@beneficiaries, items: 10)
    end

    def show
    end

    def new
      @beneficiary = Beneficiary.new
    end

    def create
      @beneficiary = Beneficiary.new(beneficiary_params)

      if @beneficiary.save
        redirect_to admin_beneficiary_path(@beneficiary), notice: "Beneficiary was successfully created."
      else
        render :new
      end
    end

    def edit
    end

    def update
      if @beneficiary.update(beneficiary_params)
        redirect_to admin_beneficiary_path(@beneficiary), notice: "Beneficiary was successfully updated."
      else
        render :edit
      end
    end

    def destroy
      if @beneficiary.destroy
        redirect_to admin_beneficiaries_path, notice: "Beneficiary was successfully deleted."
      else
        redirect_to admin_beneficiary_path(@beneficiary), alert: "Failed to delete beneficiary."
      end
    end

    private

    def set_beneficiary
      @beneficiary = Beneficiary.find_by(id: params[:id])

      unless @beneficiary
        flash[:alert] = "Beneficiary not found"
        redirect_to admin_beneficiaries_path
      end
    end

    def beneficiary_params
      params.require(:beneficiary).permit(
        :user_id, :name, :account_number, :bank_name, :bank_code,
        :branch_name, :branch_code, :phone_number, :email,
        :transfer_type, :is_favorite, :avatar
      )
    end
  end
end
