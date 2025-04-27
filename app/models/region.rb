class Region < ApplicationRecord
  # Associations
  has_many :crop_prices, dependent: :nullify
  has_many :weather_forecasts, dependent: :destroy
  has_many :crop_listings, dependent: :nullify
  
  # Validations
  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true
  
  # Scopes
  scope :alphabetical, -> { order(name: :asc) }
  
  # Geocoding (uncomment after installing geocoder gem)
  # geocoded_by :name
  # after_validation :geocode, if: ->(obj) { obj.name_changed? && obj.latitude.nil? && obj.longitude.nil? }
  
  # Methods
  def current_weather
    weather_forecasts.where("forecast_date = ?", Date.today).first
  end
  
  def upcoming_weather(days = 7)
    weather_forecasts.where("forecast_date > ? AND forecast_date <= ?", Date.today, days.days.from_now)
                     .order(forecast_date: :asc)
  end
  
  def average_crop_price(crop_id)
    crop_prices.where(crop_id: crop_id).average(:price)
  end
  
  def self.with_active_listings
    joins(:crop_listings).where("crop_listings.status = ?", 0).distinct
  end
end
