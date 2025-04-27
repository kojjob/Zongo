class CartsController < ApplicationController
  before_action :set_cart
  
  def show
    # Cart is already set in before_action
  end
  
  def add_item
    @product = Product.active.in_stock.find(params[:product_id])
    quantity = params[:quantity].to_i || 1
    
    # Ensure quantity is valid
    quantity = 1 if quantity < 1
    quantity = @product.stock_quantity if quantity > @product.stock_quantity
    
    @cart.add_product(@product, quantity)
    
    respond_to do |format|
      format.html { redirect_back(fallback_location: shop_path, notice: "#{@product.name} added to cart.") }
      format.turbo_stream
    end
  end
  
  def update_item
    @product = Product.find(params[:product_id])
    quantity = params[:quantity].to_i
    
    if quantity <= 0
      @cart.remove_product(@product)
      notice = "#{@product.name} removed from cart."
    else
      # Ensure quantity doesn't exceed stock
      quantity = @product.stock_quantity if quantity > @product.stock_quantity
      
      @cart.update_quantity(@product, quantity)
      notice = "Cart updated."
    end
    
    respond_to do |format|
      format.html { redirect_to cart_path, notice: notice }
      format.turbo_stream
    end
  end
  
  def remove_item
    @product = Product.find(params[:product_id])
    @cart.remove_product(@product)
    
    respond_to do |format|
      format.html { redirect_to cart_path, notice: "#{@product.name} removed from cart." }
      format.turbo_stream
    end
  end
  
  def clear
    @cart.clear
    
    respond_to do |format|
      format.html { redirect_to cart_path, notice: "Cart cleared." }
      format.turbo_stream
    end
  end
  
  private
  
  def set_cart
    if user_signed_in?
      # Find or create cart for logged in user
      @cart = current_user.cart || Cart.create(user: current_user)
      
      # If there was a session cart, merge it with the user's cart
      session_cart = Cart.find_by(session_id: session[:cart_id]) if session[:cart_id]
      if session_cart && session_cart.id != @cart.id
        @cart.merge_with(session_cart)
        session[:cart_id] = nil
      end
    else
      # Find or create cart for guest user
      if session[:cart_id]
        @cart = Cart.find_by(session_id: session[:cart_id])
      end
      
      unless @cart
        @cart = Cart.create(session_id: SecureRandom.hex(16))
        session[:cart_id] = @cart.session_id
      end
    end
  end
end
