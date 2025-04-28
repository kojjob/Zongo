class ShopController < ApplicationController
  before_action :set_cart
  before_action :set_categories

  def index
    @featured_categories = ShopCategory.featured.limit(6)
    @featured_products = Product.active.in_stock.featured.limit(8)
    @new_arrivals = Product.active.in_stock.new_arrivals.limit(8)
    @best_sellers = Product.active.in_stock.best_sellers.limit(8)
  end

  def category
    @category = ShopCategory.find_by!(slug: params[:slug])

    # Get all products from this category and its subcategories
    products_query = @category.all_products.active.in_stock

    # Apply filters
    if params[:min_price].present? && params[:max_price].present?
      products_query = products_query.by_price_range(params[:min_price], params[:max_price])
    end

    if params[:sort].present?
      case params[:sort]
      when 'price_asc'
        products_query = products_query.order(price: :asc)
      when 'price_desc'
        products_query = products_query.order(price: :desc)
      when 'newest'
        products_query = products_query.order(created_at: :desc)
      when 'popular'
        products_query = products_query.left_joins(:order_items).group(:id).order('COUNT(order_items.id) DESC')
      else
        products_query = products_query.order(created_at: :desc)
      end
    else
      products_query = products_query.order(created_at: :desc)
    end

    # Paginate results
    @pagy, @products = pagy(products_query, items: 12)

    # Get subcategories
    @subcategories = @category.subcategories.active
  end

  def product
    @product = Product.active.find(params[:id])
    @related_products = @product.related_products(4)
    @reviews = @product.reviews.approved.recent.limit(5)
  end

  def search
    # Redirect to the new search controller
    redirect_to search_path(params.permit(:q, :category_id, :min_price, :max_price, :sort))
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

  def set_categories
    @categories = ShopCategory.root_categories.active
  end
end
