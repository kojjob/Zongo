class AgricultureController < ApplicationController
  before_action :authenticate_user!, except: [:index]

  def index
    begin
      @featured_crops = Crop.where(featured: true).limit(6)
      @recent_listings = CropListing.active.recent.limit(8)
      @featured_resources = AgricultureResource.published.featured.limit(3)

      # Get weather forecasts for popular regions
      @weather_forecasts = WeatherForecast.where(forecast_date: Date.today).includes(:region).limit(5)

      # Get trending crops (those with significant price changes)
      @trending_crops = Crop.joins(:crop_prices)
                            .select('crops.*, MAX(crop_prices.date) as latest_date')
                            .group('crops.id')
                            .order('latest_date DESC')
                            .limit(5)

      # Get in-season crops
      @in_season_crops = Crop.where(featured: true)
                             .select { |crop| crop.in_season? }
                             .first(4)
    rescue => e
      Rails.logger.error("Error in AgricultureController#index: #{e.message}")
      @featured_crops = []
      @recent_listings = []
      @featured_resources = []
      @weather_forecasts = []
      @trending_crops = []
      @in_season_crops = []
    end
  end
end
