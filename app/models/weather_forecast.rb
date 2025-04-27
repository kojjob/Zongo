class WeatherForecast < ApplicationRecord
  # Associations
  belongs_to :region

  # Validations
  validates :forecast_date, presence: true
  validates :temperature_high, presence: true, numericality: true
  validates :temperature_low, presence: true, numericality: true
  validates :precipitation_chance, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :precipitation_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :weather_condition, presence: true

  # Enums
  enum :weather_condition, {
    sunny: 0,
    partly_cloudy: 1,
    cloudy: 2,
    rainy: 3,
    stormy: 4,
    windy: 5,
    foggy: 6,
    snowy: 7
  }, default: :partly_cloudy

  # Scopes
  scope :upcoming, -> { where("forecast_date >= ?", Date.today).order(forecast_date: :asc) }
  scope :past, -> { where("forecast_date < ?", Date.today).order(forecast_date: :desc) }
  scope :today, -> { where(forecast_date: Date.today) }
  scope :this_week, -> { where(forecast_date: Date.today..6.days.from_now) }

  # Methods
  def favorable_for_planting?
    # Logic for determining if weather is good for planting
    # Generally, moderate temperatures, some precipitation but not too much
    temperature_avg = (temperature_high + temperature_low) / 2
    temperature_avg.between?(20, 30) &&
      precipitation_chance.between?(20, 70) &&
      precipitation_amount.between?(1, 15) &&
      !stormy? && !windy?
  end

  def favorable_for_harvesting?
    # Logic for determining if weather is good for harvesting
    # Generally, dry conditions, moderate temperatures
    precipitation_chance < 30 &&
      precipitation_amount < 5 &&
      !rainy? && !stormy? && !foggy?
  end

  def weather_icon
    case weather_condition
    when 'sunny' then 'sun'
    when 'partly_cloudy' then 'cloud-sun'
    when 'cloudy' then 'cloud'
    when 'rainy' then 'cloud-rain'
    when 'stormy' then 'cloud-lightning'
    when 'windy' then 'wind'
    when 'foggy' then 'cloud-fog'
    when 'snowy' then 'snowflake'
    else 'question'
    end
  end

  def weather_alert?
    # Check if weather conditions warrant an alert
    stormy? ||
      precipitation_amount > 20 ||
      temperature_high > 35 ||
      temperature_low < 5
  end

  def weather_alert_message
    return nil unless weather_alert?

    if stormy?
      "Storm warning: Take precautions to protect crops and livestock."
    elsif precipitation_amount > 20
      "Heavy rain warning: Potential flooding in low-lying areas."
    elsif temperature_high > 35
      "Extreme heat warning: Ensure adequate irrigation for crops."
    elsif temperature_low < 5
      "Frost warning: Protect sensitive crops from cold damage."
    end
  end
end
