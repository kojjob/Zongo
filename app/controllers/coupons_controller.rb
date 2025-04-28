class CouponsController < ApplicationController
  before_action :authenticate_user!
  
  def apply
    @coupon = Coupon.find_by(code: params[:code].strip.upcase)
    
    if @coupon.nil?
      render json: { success: false, message: 'Invalid coupon code.' }
      return
    end
    
    unless @coupon.active?
      render json: { success: false, message: 'This coupon is not active.' }
      return
    end
    
    if @coupon.expired?
      render json: { success: false, message: 'This coupon has expired.' }
      return
    end
    
    if @coupon.usage_limit_reached?
      render json: { success: false, message: 'This coupon has reached its usage limit.' }
      return
    end
    
    # Get the current cart
    @cart = current_user.cart || current_user.create_cart
    
    # Check if the coupon is valid for the current cart
    unless @coupon.valid_for_order?(@cart)
      message = if @coupon.minimum_order_amount.present? && @cart.total < @coupon.minimum_order_amount
                  "This coupon requires a minimum order amount of GHS #{@coupon.minimum_order_amount}."
                elsif @coupon.first_time_purchase_only && current_user.orders.completed.exists?
                  "This coupon is only valid for first-time purchases."
                elsif @coupon.shop_category_id.present? && !@cart.cart_items.joins(:product).where(products: { shop_category_id: @coupon.shop_category_id }).exists?
                  "This coupon is only valid for products in the #{@coupon.shop_category.name} category."
                else
                  "This coupon cannot be applied to your current order."
                end
      
      render json: { success: false, message: message }
      return
    end
    
    # Calculate the discount amount
    discount_amount = @coupon.calculate_discount_amount(@cart.total)
    
    # Store the coupon in the session
    session[:coupon_id] = @coupon.id
    session[:coupon_code] = @coupon.code
    session[:coupon_discount] = discount_amount
    
    render json: {
      success: true,
      message: 'Coupon applied successfully!',
      discount_amount: discount_amount,
      formatted_discount: helpers.number_to_currency(discount_amount, unit: 'GHS '),
      new_total: helpers.number_to_currency(@cart.total - discount_amount, unit: 'GHS ')
    }
  end
  
  def remove
    session.delete(:coupon_id)
    session.delete(:coupon_code)
    session.delete(:coupon_discount)
    
    # Get the current cart
    @cart = current_user.cart || current_user.create_cart
    
    render json: {
      success: true,
      message: 'Coupon removed successfully!',
      new_total: helpers.number_to_currency(@cart.total, unit: 'GHS ')
    }
  end
end
