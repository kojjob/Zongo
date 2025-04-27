module Agriculture
  class BaseController < ApplicationController
    before_action :authenticate_user!, except: [:crop_prices, :weather, :resources, :marketplace]

    def crop_prices
      begin
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
        @prices = if @selected_crop.present?
          prices = CropPrice.where(crop_id: @selected_crop.id)
          prices = prices.where(region_id: @selected_region.id) if @selected_region.present?
          prices.order(date: :desc).limit(30)
        else
          CropPrice.none
        end

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
          @price_change_percentage = (@price_change / @prices.second.price * 100).round(2) rescue 0
        else
          @price_change = 0
          @price_change_percentage = 0
        end
      rescue => e
        Rails.logger.error("Error in Agriculture::BaseController#crop_prices: #{e.message}")
        @crops = []
        @regions = []
        @selected_crop = nil
        @selected_region = nil
        @prices = []
        @chart_data = []
        @current_price = 0
        @avg_price = 0
        @min_price = 0
        @max_price = 0
        @price_change = 0
        @price_change_percentage = 0
      end
    end

    def weather
      begin
        @regions = Region.all.order(:name)

        # Filter by region if provided
        if params[:region_id].present?
          @selected_region = Region.find_by(id: params[:region_id])
        else
          @selected_region = @regions.first
        end

        # Get weather forecasts for the selected region
        @forecasts = if @selected_region.present?
          WeatherForecast.where(region_id: @selected_region.id)
                        .where('forecast_date >= ?', Date.today)
                        .order(forecast_date: :asc)
                        .limit(7)
        else
          WeatherForecast.none
        end

        # Get current weather
        @current_weather = if @forecasts.present?
          @forecasts.find_by(forecast_date: Date.today) ||
            (@selected_region.present? ? WeatherForecast.where(forecast_date: Date.today, region_id: @selected_region.id).first : nil)
        else
          nil
        end

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
      rescue => e
        Rails.logger.error("Error in Agriculture::BaseController#weather: #{e.message}")
        @regions = []
        @selected_region = nil
        @forecasts = []
        @current_weather = nil
        @planting_recommendations = []
        @harvesting_recommendations = []
        @weather_alerts = []
      end
    end

    def marketplace
      begin
        listings_query = CropListing.active.includes(:crop, :region, :user)

        # Apply filters
        listings_query = listings_query.by_crop(params[:crop_id]) if params[:crop_id].present?
        listings_query = listings_query.by_region(params[:region_id]) if params[:region_id].present?
        listings_query = listings_query.where(listing_type: params[:listing_type]) if params[:listing_type].present?

        if params[:min_price].present? && params[:max_price].present?
          listings_query = listings_query.by_price_range(params[:min_price], params[:max_price])
        end

        # Sort listings
        case params[:sort]
        when 'price_asc'
          listings_query = listings_query.order(price: :asc)
        when 'price_desc'
          listings_query = listings_query.order(price: :desc)
        when 'newest'
          listings_query = listings_query.order(created_at: :desc)
        when 'oldest'
          listings_query = listings_query.order(created_at: :asc)
        else
          listings_query = listings_query.order(created_at: :desc)
        end

        # Paginate results using Pagy
        @pagy, @listings = pagy(listings_query, items: 12)

        # Get filter options
        @crops = Crop.all.order(:name)
        @regions = Region.all.order(:name)
      rescue => e
        Rails.logger.error("Error in Agriculture::BaseController#marketplace: #{e.message}")
        @listings = []
        @pagy = Pagy.new(count: 0, page: 1)
        @crops = []
        @regions = []
      end
    end

    def resources
      begin
        resources_query = AgricultureResource.published.includes(:crop)

        # Apply filters
        resources_query = resources_query.by_crop(params[:crop_id]) if params[:crop_id].present?
        resources_query = resources_query.by_type(params[:resource_type]) if params[:resource_type].present?

        # Search
        resources_query = resources_query.search(params[:query]) if params[:query].present?

        # Sort resources
        case params[:sort]
        when 'newest'
          resources_query = resources_query.order(created_at: :desc)
        when 'popular'
          resources_query = resources_query.order(view_count: :desc)
        else
          resources_query = resources_query.order(created_at: :desc)
        end

        # Paginate results using Pagy
        @pagy, @resources = pagy(resources_query, items: 9)

        # Get filter options
        @crops = Crop.all.order(:name)
        @resource_types = AgricultureResource.resource_types.keys.map do |type|
          [type.titleize, type]
        end

        # Get featured resources for sidebar
        @featured_resources = AgricultureResource.published.featured.limit(3)
      rescue => e
        Rails.logger.error("Error in Agriculture::BaseController#resources: #{e.message}")
        @resources = []
        @pagy = Pagy.new(count: 0, page: 1)
        @crops = []
        @resource_types = []
        @featured_resources = []
      end
    end
  end
end
