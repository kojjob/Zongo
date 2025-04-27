class CropPrice < ApplicationRecord
  # Associations
  belongs_to :crop
  belongs_to :region, optional: true
  
  # Validations
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :date, presence: true
  validates :unit, presence: true
  validates :market, presence: true
  
  # Scopes
  scope :recent, -> { order(date: :desc) }
  scope :by_region, ->(region_id) { where(region_id: region_id) }
  scope :by_market, ->(market) { where(market: market) }
  scope :last_30_days, -> { where("date >= ?", 30.days.ago) }
  scope :last_90_days, -> { where("date >= ?", 90.days.ago) }
  
  # Methods
  def self.average_for_period(start_date, end_date, crop_id = nil)
    scope = where(date: start_date..end_date)
    scope = scope.where(crop_id: crop_id) if crop_id.present?
    scope.average(:price)
  end
  
  def self.min_for_period(start_date, end_date, crop_id = nil)
    scope = where(date: start_date..end_date)
    scope = scope.where(crop_id: crop_id) if crop_id.present?
    scope.minimum(:price)
  end
  
  def self.max_for_period(start_date, end_date, crop_id = nil)
    scope = where(date: start_date..end_date)
    scope = scope.where(crop_id: crop_id) if crop_id.present?
    scope.maximum(:price)
  end
  
  def self.price_trend(crop_id, days = 30, interval = 'day')
    prices = where(crop_id: crop_id)
             .where("date >= ?", days.days.ago)
    
    case interval
    when 'day'
      prices.group("DATE(date)").average(:price)
    when 'week'
      prices.group("EXTRACT(WEEK FROM date)").average(:price)
    when 'month'
      prices.group("EXTRACT(MONTH FROM date)").average(:price)
    end
  end
end
