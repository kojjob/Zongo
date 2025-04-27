class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_cart, only: [:new, :create]
  before_action :set_order, only: [:show, :cancel]
  
  def index
    @pagy, @orders = pagy(current_user.orders.recent, items: 10)
  end
  
  def show
    # Order is set in before_action
  end
  
  def new
    if @cart.empty?
      redirect_to cart_path, alert: "Your cart is empty."
      return
    end
    
    @order = current_user.orders.new
  end
  
  def create
    if @cart.empty?
      redirect_to cart_path, alert: "Your cart is empty."
      return
    end
    
    @order = current_user.orders.new(order_params)
    @order.total_amount = @cart.total_price
    
    # Check if all products are still available
    unavailable_products = []
    @cart.cart_items.each do |item|
      product = item.product.reload
      if !product.active? || product.stock_quantity < item.quantity
        unavailable_products << product.name
      end
    end
    
    if unavailable_products.any?
      redirect_to cart_path, alert: "Some products are no longer available: #{unavailable_products.join(', ')}"
      return
    end
    
    if @order.save
      # Add items from cart to order
      @order.add_from_cart(@cart)
      
      # Clear the cart
      @cart.clear
      
      # Create a transaction for the order
      transaction = current_user.transactions.create(
        transaction_type: :purchase,
        amount: @order.total_amount,
        status: :pending,
        description: "Order ##{@order.order_number}",
        metadata: { order_id: @order.id }
      )
      
      # Associate transaction with order
      @order.update(transaction: transaction)
      
      redirect_to order_path(@order), notice: "Order placed successfully."
    else
      render :new
    end
  end
  
  def cancel
    if @order.can_cancel?
      if @order.cancel
        redirect_to order_path(@order), notice: "Order cancelled successfully."
      else
        redirect_to order_path(@order), alert: "Failed to cancel order."
      end
    else
      redirect_to order_path(@order), alert: "This order cannot be cancelled."
    end
  end
  
  private
  
  def set_order
    @order = current_user.orders.find(params[:id])
  end
  
  def set_cart
    @cart = current_user.cart || Cart.create(user: current_user)
  end
  
  def order_params
    params.require(:order).permit(:shipping_address, :billing_address, :payment_method, :notes)
  end
end
