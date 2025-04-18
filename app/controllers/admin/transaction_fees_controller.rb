class Admin::TransactionFeesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin
  before_action :set_transaction_fee, only: [ :show, :edit, :update, :destroy, :toggle_active ]

  def index
    @transaction_fees = TransactionFee.all.order(created_at: :desc)
  end

  def show
  end

  def new
    @transaction_fee = TransactionFee.new
  end

  def create
    @transaction_fee = TransactionFee.new(transaction_fee_params)

    if @transaction_fee.save
      flash[:success] = "Transaction fee was successfully created."
      redirect_to admin_transaction_fees_path
    else
      flash.now[:error] = @transaction_fee.errors.full_messages.to_sentence
      render :new
    end
  end

  def edit
  end

  def update
    if @transaction_fee.update(transaction_fee_params)
      flash[:success] = "Transaction fee was successfully updated."
      redirect_to admin_transaction_fees_path
    else
      flash.now[:error] = @transaction_fee.errors.full_messages.to_sentence
      render :edit
    end
  end

  def destroy
    @transaction_fee.destroy
    flash[:success] = "Transaction fee was successfully deleted."
    redirect_to admin_transaction_fees_path
  end

  def toggle_active
    @transaction_fee.update(active: !@transaction_fee.active)
    flash[:success] = "Transaction fee is now #{@transaction_fee.active? ? 'active' : 'inactive'}."
    redirect_to admin_transaction_fees_path
  end

  private

  def set_transaction_fee
    @transaction_fee = TransactionFee.find(params[:id])
  end

  def transaction_fee_params
    params.require(:transaction_fee).permit(
      :name,
      :transaction_type,
      :fee_type,
      :fixed_amount,
      :percentage,
      :min_fee,
      :max_fee,
      :active,
      :description
    )
  end

  def ensure_admin
    unless current_user.admin?
      flash[:error] = "You are not authorized to access this page."
      redirect_to root_path
    end
  end
end
