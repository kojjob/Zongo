class PaymentMethodsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_payment_method, only: [ :show, :edit, :update, :destroy, :set_default, :verify ]
  before_action :ensure_ownership, only: [ :show, :edit, :update, :destroy, :set_default, :verify ]

  def index
    @payment_methods = current_user.payment_methods.order(default: :desc, created_at: :desc)
  end

  def show
  end

  def new
    @payment_method = PaymentMethod.new
  end

  def create
    @payment_method = PaymentMethod.new(payment_method_params)
    @payment_method.user = current_user

    # If this is the first payment method, make it default
    @payment_method.default = true if current_user.payment_methods.empty?

    if @payment_method.save
      flash[:success] = "Payment method added successfully"
      redirect_to payment_methods_path
    else
      flash.now[:error] = "Failed to add payment method: #{@payment_method.errors.full_messages.join(', ')}"
      render :new
    end
  end

  def edit
  end

  def update
    if @payment_method.update(payment_method_params)
      flash[:success] = "Payment method updated successfully"
      redirect_to payment_methods_path
    else
      flash.now[:error] = "Failed to update payment method: #{@payment_method.errors.full_messages.join(', ')}"
      render :edit
    end
  end

  def destroy
    if @payment_method.destroy
      flash[:success] = "Payment method removed successfully"
    else
      flash[:error] = "Failed to remove payment method"
    end
    redirect_to payment_methods_path
  end

  def set_default
    if @payment_method.update(default: true)
      # Unset default flag on all other payment methods
      current_user.payment_methods.where.not(id: @payment_method.id).update_all(default: false)
      flash[:success] = "Default payment method updated"
    else
      flash[:error] = "Failed to update default payment method"
    end
    redirect_to payment_methods_path
  end

  def verify
    # In a real application, this would initiate a verification process
    # For demo purposes, we'll just mark it as verified
    if @payment_method.update(status: :verified, verification_status: :verification_approved)
      # Also mark as used now
      @payment_method.mark_as_used!
      flash[:success] = "Payment method verified successfully"
    else
      flash[:error] = "Failed to verify payment method: #{@payment_method.errors.full_messages.join(', ')}"
    end
    redirect_to payment_methods_path
  end

  private

  def set_payment_method
    @payment_method = PaymentMethod.find(params[:id])
  end

  def ensure_ownership
    unless @payment_method.user_id == current_user.id
      flash[:error] = "You don't have permission to access this payment method"
      redirect_to payment_methods_path
    end
  end

  def payment_method_params
    params.require(:payment_method).permit(
      :method_type, :provider, :account_number, :account_name,
      :expiry_date, :description, :default, :icon_name
    )
  end
end
