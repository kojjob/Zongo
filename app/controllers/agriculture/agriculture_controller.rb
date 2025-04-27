module Agriculture
  class AgricultureController < ApplicationController
    before_action :authenticate_user!, except: [:index, :crop_prices, :weather, :resources]
    
    def crop_prices
      @crops = Crop.all.order(:name)
      @regions = Region.all.order(:name)
      
      # Filter by crop if provided
      if params[:crop_id].present?
        @selected_crop = Crop.find_by(id: params[:crop_id])
      else
        @selected_crop = @crops.first
      end
      
      # Filter by region if provided
      if params[:region_id].present?
        @selected_region = Region.find_by(id: params[:region_id])
      end
      
      # Get price data for the selected crop
      @prices = CropPrice.where(crop_id: @selected_crop&.id)
      @prices = @prices.where(region_id: @selected_region.id) if @selected_region.present?
      @prices = @prices.order(date: :desc).limit(30)
      
      # Prepare data for chart
      @chart_data = @prices.order(date: :asc).last(30).map do |price|
        {
          date: price.date.strftime('%b %d'),
          price: price.price
        }
      end
      
      # Get price statistics
      @current_price = @prices.first&.price || 0
      @avg_price = @prices.average(:price)&.round(2) || 0
      @min_price = @prices.minimum(:price) || 0
      @max_price = @prices.maximum(:price) || 0
      
      # Calculate price change
      if @prices.count >= 2
        @price_change = @current_price - @prices.second.price
        @price_change_percentage = (@price_change / @prices.second.price * 100).round(2)
      else
        @price_change = 0
        @price_change_percentage = 0
      end
    end
    
    def weather
      @regions = Region.all.order(:name)
      
      # Filter by region if provided
      if params[:region_id].present?
        @selected_region = Region.find_by(id: params[:region_id])
      else
        @selected_region = @regions.first
      end
      
      # Get weather forecasts for the selected region
      @forecasts = WeatherForecast.where(region_id: @selected_region&.id)
                                 .where('forecast_date >= ?', Date.today)
                                 .order(forecast_date: :asc)
                                 .limit(7)
      
      # Get current weather
      @current_weather = @forecasts.find_by(forecast_date: Date.today)
      
      # Get planting recommendations based on weather
      @planting_recommendations = []
      @harvesting_recommendations = []
      
      if @current_weather.present?
        # Find crops suitable for planting in current weather conditions
        if @current_weather.favorable_for_planting?
          @planting_recommendations = Crop.where(featured: true)
                                         .select { |crop| crop.in_season? }
                                         .first(3)
        end
        
        # Find crops suitable for harvesting in current weather conditions
        if @current_weather.favorable_for_harvesting?
          @harvesting_recommendations = Crop.where(featured: true)
                                           .first(3)
        end
      end
      
      # Check for weather alerts
      @weather_alerts = @forecasts.select(&:weather_alert?)
    end
    
    def marketplace
      @listings = CropListing.active.includes(:crop, :region, :user)
      
      # Apply filters
      @listings = @listings.by_crop(params[:crop_id]) if params[:crop_id].present?
      @listings = @listings.by_region(params[:region_id]) if params[:region_id].present?
      @listings = @listings.where(listing_type: params[:listing_type]) if params[:listing_type].present?
      
      if params[:min_price].present? && params[:max_price].present?
        @listings = @listings.by_price_range(params[:min_price], params[:max_price])
      end
      
      # Sort listings
      case params[:sort]
      when 'price_asc'
        @listings = @listings.order(price: :asc)
      when 'price_desc'
        @listings = @listings.order(price: :desc)
      when 'newest'
        @listings = @listings.order(created_at: :desc)
      when 'oldest'
        @listings = @listings.order(created_at: :asc)
      else
        @listings = @listings.order(created_at: :desc)
      end
      
      # Paginate results
      @listings = @listings.page(params[:page]).per(12)
      
      # Get filter options
      @crops = Crop.all.order(:name)
      @regions = Region.all.order(:name)
    end
    
    def resources
      @resources = AgricultureResource.published.includes(:crop)
      
      # Apply filters
      @resources = @resources.by_crop(params[:crop_id]) if params[:crop_id].present?
      @resources = @resources.by_type(params[:resource_type]) if params[:resource_type].present?
      
      # Search
      @resources = @resources.search(params[:query]) if params[:query].present?
      
      # Sort resources
      case params[:sort]
      when 'newest'
        @resources = @resources.order(created_at: :desc)
      when 'popular'
        @resources = @resources.order(view_count: :desc)
      else
        @resources = @resources.order(created_at: :desc)
      end
      
      # Paginate results
      @resources = @resources.page(params[:page]).per(9)
      
      # Get filter options
      @crops = Crop.all.order(:name)
      @resource_types = AgricultureResource.resource_types.keys.map do |type|
        [type.titleize, type]
      end
      
      # Get featured resources for sidebar
      @featured_resources = AgricultureResource.published.featured.limit(3)
    end
  end
end
