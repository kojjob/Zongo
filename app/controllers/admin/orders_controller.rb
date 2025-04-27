module Admin
  class OrdersController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin
    before_action :set_order, only: [:show, :edit, :update, :process_order, :ship, :deliver, :cancel, :refund]
    layout "admin"
    
    def index
      orders_query = Order.all.includes(:user)
      
      # Apply filters
      if params[:user_id].present?
        orders_query = orders_query.where(user_id: params[:user_id])
      end
      
      if params[:status].present?
        orders_query = orders_query.where(status: params[:status])
      end
      
      if params[:min_amount].present? && params[:max_amount].present?
        orders_query = orders_query.where(total_amount: params[:min_amount]..params[:max_amount])
      end
      
      if params[:start_date].present? && params[:end_date].present?
        orders_query = orders_query.where(created_at: params[:start_date].to_date.beginning_of_day..params[:end_date].to_date.end_of_day)
      end
      
      if params[:search].present?
        orders_query = orders_query.where("order_number ILIKE ? OR notes ILIKE ?", 
                                        "%#{params[:search]}%", 
                                        "%#{params[:search]}%")
      end
      
      # Apply sorting
      case params[:sort]
      when "newest"
        orders_query = orders_query.order(created_at: :desc)
      when "oldest"
        orders_query = orders_query.order(created_at: :asc)
      when "amount_high"
        orders_query = orders_query.order(total_amount: :desc)
      when "amount_low"
        orders_query = orders_query.order(total_amount: :asc)
      else
        orders_query = orders_query.order(created_at: :desc)
      end
      
      @pagy, @orders = pagy(orders_query, items: 20)
    end
    
    def show
      @order_items = @order.order_items.includes(:product)
    end
    
    def edit
    end
    
    def update
      if @order.update(order_params)
        redirect_to admin_order_path(@order), notice: "Order was successfully updated."
      else
        render :edit
      end
    end
    
    def process_order
      @order.update(status: :processing)
      redirect_to admin_order_path(@order), notice: "Order is now being processed."
    end
    
    def ship
      @order.update(status: :shipped, shipped_at: Time.current)
      redirect_to admin_order_path(@order), notice: "Order has been marked as shipped."
    end
    
    def deliver
      @order.update(status: :delivered, delivered_at: Time.current)
      redirect_to admin_order_path(@order), notice: "Order has been marked as delivered."
    end
    
    def cancel
      if @order.cancel
        redirect_to admin_order_path(@order), notice: "Order has been cancelled."
      else
        redirect_to admin_order_path(@order), alert: "Failed to cancel order."
      end
    end
    
    def refund
      @order.update(status: :refunded)
      redirect_to admin_order_path(@order), notice: "Order has been marked as refunded."
    end
    
    private
    
    def set_order
      @order = Order.find(params[:id])
    end
    
    def order_params
      params.require(:order).permit(:status, :shipping_address, :billing_address, :tracking_number, :notes)
    end
  end
end
