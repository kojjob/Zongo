module Admin
  class PaymentMethodsController < BaseController
    before_action :set_payment_method, only: [:show, :edit, :update, :destroy, :verify, :set_default]

    def index
      @payment_methods = PaymentMethod.all.order(created_at: :desc)

      # Filter by method type if provided
      if params[:method_type].present?
        @payment_methods = @payment_methods.where(method_type: params[:method_type])
      end

      # Filter by status if provided
      if params[:status].present?
        @payment_methods = @payment_methods.where(status: params[:status])
      end

      # Filter by user if provided
      if params[:user_id].present?
        @payment_methods = @payment_methods.where(user_id: params[:user_id])
      end

      # Filter by search term if provided
      if params[:search].present?
        @payment_methods = @payment_methods.where("provider LIKE ? OR last_four LIKE ? OR account_name LIKE ?",
                                                "%#{params[:search]}%",
                                                "%#{params[:search]}%",
                                                "%#{params[:search]}%")
      end

      # Paginate results
      @pagy, @payment_methods = pagy(@payment_methods, items: 10)
    end

    def show
    end

    def new
      @payment_method = PaymentMethod.new
    end

    def create
      @payment_method = PaymentMethod.new(payment_method_params)

      if @payment_method.save
        redirect_to admin_payment_method_path(@payment_method), notice: "Payment method was successfully created."
      else
        render :new
      end
    end

    def edit
    end

    def update
      if @payment_method.update(payment_method_params)
        redirect_to admin_payment_method_path(@payment_method), notice: "Payment method was successfully updated."
      else
        render :edit
      end
    end

    def destroy
      if @payment_method.destroy
        redirect_to admin_payment_methods_path, notice: "Payment method was successfully deleted."
      else
        redirect_to admin_payment_method_path(@payment_method), alert: "Failed to delete payment method."
      end
    end

    def verify
      if @payment_method.update(status: :verified, verified_at: Time.current)
        redirect_to admin_payment_method_path(@payment_method), notice: "Payment method has been verified."
      else
        redirect_to admin_payment_method_path(@payment_method), alert: "Failed to verify payment method."
      end
    end

    def set_default
      user = @payment_method.user

      # First, unset default for all other payment methods of this user
      user.payment_methods.where.not(id: @payment_method.id).update_all(default: false)

      # Then set this one as default
      if @payment_method.update(default: true)
        redirect_to admin_payment_method_path(@payment_method), notice: "Payment method has been set as default."
      else
        redirect_to admin_payment_method_path(@payment_method), alert: "Failed to set payment method as default."
      end
    end

    private

    def set_payment_method
      @payment_method = PaymentMethod.find_by(id: params[:id])

      unless @payment_method
        flash[:alert] = "Payment method not found"
        redirect_to admin_payment_methods_path
      end
    end

    def payment_method_params
      params.require(:payment_method).permit(
        :user_id, :method_type, :provider, :account_name,
        :account_number, :routing_number, :last_four, :expiry_month,
        :expiry_year, :card_type, :status, :default, :token,
        :phone_number, :network, :metadata
      )
    end
  end
end
