class SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    @category_id = params[:category_id]
    @min_price = params[:min_price]
    @max_price = params[:max_price]
    @sort = params[:sort] || 'relevance'
    @rating = params[:rating]
    @product_type = params[:product_type]

    # Base query
    @products = Product.active.includes(:shop_category, :reviews)

    # Apply search query
    if @query.present?
      # Log search query for analytics
      SearchQuery.create(
        query: @query,
        user: current_user,
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        results_count: 0 # Will update after search
      ) if Rails.env.production?

      # Search in product name, description, and SKU
      @products = @products.where("name ILIKE ? OR description ILIKE ? OR sku ILIKE ?",
                                 "%#{@query}%", "%#{@query}%", "%#{@query}%")
    end

    # Apply category filter
    if @category_id.present?
      @products = @products.where(shop_category_id: @category_id)
    end

    # Apply price range filter
    if @min_price.present?
      @products = @products.where("price >= ?", @min_price)
    end

    if @max_price.present?
      @products = @products.where("price <= ?", @max_price)
    end

    # Apply rating filter
    if @rating.present?
      @products = @products.joins(:reviews)
                          .group('products.id')
                          .having('AVG(reviews.rating) >= ?', @rating)
    end

    # Apply product type filter
    if @product_type.present?
      @products = @products.where(product_type: @product_type)
    end

    # Apply sorting
    case @sort
    when 'price_asc'
      @products = @products.order(price: :asc)
    when 'price_desc'
      @products = @products.order(price: :desc)
    when 'newest'
      @products = @products.order(created_at: :desc)
    when 'rating'
      @products = @products.left_joins(:reviews)
                          .group('products.id')
                          .order('AVG(reviews.rating) DESC NULLS LAST')
    when 'popularity'
      @products = @products.left_joins(:order_items)
                          .group('products.id')
                          .order('COUNT(order_items.id) DESC')
    else
      # Default relevance sorting for search queries
      if @query.present?
        # Custom relevance scoring based on match location
        # Products with matches in name are ranked higher than those with matches in description
        @products = @products.select("products.*,
                                    CASE
                                      WHEN name ILIKE '%#{ActiveRecord::Base.connection.quote_string(@query)}%' THEN 3
                                      WHEN sku ILIKE '%#{ActiveRecord::Base.connection.quote_string(@query)}%' THEN 2
                                      ELSE 1
                                    END as relevance_score")
                            .order('relevance_score DESC, created_at DESC')
      else
        # Default to newest if no search query
        @products = @products.order(created_at: :desc)
      end
    end

    # Pagination
    @pagy, @products = pagy(@products, items: 24)

    # Get categories for filter
    @categories = ShopCategory.all.order(:name)

    # Get price range for filter
    min_price = Product.minimum(:price)
    max_price = Product.maximum(:price)

    @price_range = {
      min: min_price ? min_price.to_i : 0,
      max: max_price ? max_price.ceil : 1000
    }

    # Update search query with results count
    if Rails.env.production? && @query.present?
      SearchQuery.where(query: @query)
                .where('created_at > ?', 5.minutes.ago)
                .update_all(results_count: @pagy.count)
    end

    respond_to do |format|
      format.html
      format.json {
        render json: {
          products: @products.map { |p| {
            id: p.id,
            name: p.name,
            price: p.price,
            image_url: p.images.attached? ? url_for(p.images.first.variant(resize_to_fill: [100, 100])) : nil,
            url: product_path(p)
          }}
        }
      }
    end
  end

  def autocomplete
    query = params[:q].to_s.strip

    if query.length < 2
      render json: { suggestions: [] }
      return
    end

    # Get product suggestions
    product_suggestions = Product.active
                                .where("name ILIKE ?", "%#{query}%")
                                .order(Arel.sql("CASE WHEN name ILIKE '#{ActiveRecord::Base.connection.quote_string(query)}%' THEN 0 ELSE 1 END"))
                                .limit(5)
                                .pluck(:name)

    # Get category suggestions
    category_suggestions = ShopCategory.where("name ILIKE ?", "%#{query}%")
                                      .limit(3)
                                      .pluck(:name)

    # Get popular search suggestions from past searches
    popular_suggestions = []
    if Rails.env.production?
      popular_suggestions = SearchQuery.where("query ILIKE ?", "%#{query}%")
                                      .group(:query)
                                      .order('COUNT(id) DESC')
                                      .limit(3)
                                      .pluck(:query)
    end

    # Combine and deduplicate suggestions
    all_suggestions = (product_suggestions + category_suggestions + popular_suggestions).uniq

    # Limit to 8 suggestions total
    suggestions = all_suggestions.first(8)

    render json: { suggestions: suggestions }
  end
end
