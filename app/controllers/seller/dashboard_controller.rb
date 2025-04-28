module Seller
  class DashboardController < BaseController
    def index
      @products_count = current_user.products.count
      @active_products_count = current_user.products.active.count
      @inactive_products_count = current_user.products.inactive.count
      @out_of_stock_products_count = current_user.products.out_of_stock.count
      
      @recent_products = current_user.products.order(created_at: :desc).limit(5)
      @low_stock_products = current_user.products.where("stock_quantity > 0 AND stock_quantity <= 5").limit(5)
      
      # Get recent orders for this seller's products
      @recent_orders = Order.joins(:order_items)
                           .where(order_items: { product_id: current_user.products.pluck(:id) })
                           .distinct
                           .order(created_at: :desc)
                           .limit(5)
    end
  end
end
