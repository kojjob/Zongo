class Crop < ApplicationRecord
  # Associations
  has_many :crop_prices, dependent: :destroy
  has_many :crop_listings, dependent: :destroy
  has_many :crop_resources, dependent: :destroy

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :growing_season, presence: true
  validates :category, presence: true

  # Enums
  enum :category, {
    grain: 0,
    vegetable: 1,
    fruit: 2,
    root: 3,
    legume: 4,
    cash_crop: 5,
    other: 6
  }, prefix: true

  # Scopes
  scope :popular, -> { order(popularity: :desc).limit(10) }
  scope :in_season, -> { where("? BETWEEN season_start AND season_end", Date.today) }
  scope :by_category, ->(category) { where(category: category) }

  # Active Storage
  has_one_attached :image

  # Methods
  def current_price
    crop_prices.order(date: :desc).first&.price || 0
  end

  def price_trend(days = 30)
    crop_prices.where("date >= ?", days.days.ago).order(date: :asc)
  end

  def price_change_percentage(days = 30)
    prices = price_trend(days)
    return 0 if prices.count < 2

    oldest = prices.first.price
    newest = prices.last.price
    return 0 if oldest.zero?

    ((newest - oldest) / oldest * 100).round(2)
  end

  def in_season?
    current_month = Date.today.month

    if season_start <= season_end
      current_month >= season_start && current_month <= season_end
    else
      # Handles seasons that span across years (e.g., Nov-Feb)
      current_month >= season_start || current_month <= season_end
    end
  end
end
