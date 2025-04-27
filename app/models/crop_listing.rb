class CropListing < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :crop
  belongs_to :region, optional: true
  has_many :crop_listing_inquiries, dependent: :destroy

  # Validations
  validates :title, presence: true
  validates :description, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit, presence: true
  validates :listing_type, presence: true
  validates :status, presence: true

  # Enums
  enum :listing_type, {
    selling: 0,
    buying: 1
  }, default: :selling

  enum :status, {
    active: 0,
    pending: 1,
    sold: 2,
    expired: 3,
    cancelled: 4
  }, default: :pending

  # Active Storage
  has_many_attached :images

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :selling, -> { where(listing_type: :selling) }
  scope :buying, -> { where(listing_type: :buying) }
  scope :by_crop, ->(crop_id) { where(crop_id: crop_id) }
  scope :by_region, ->(region_id) { where(region_id: region_id) }
  scope :by_price_range, ->(min, max) { where(price: min..max) }
  scope :featured, -> { where(featured: true) }

  # Callbacks
  before_create :set_expiry_date

  # Methods
  def expired?
    expiry_date.present? && expiry_date < Date.today
  end

  def days_until_expiry
    return 0 if expired?
    (expiry_date - Date.today).to_i
  end

  def formatted_price
    "GHS #{price.round(2)}/#{unit}"
  end

  def total_value
    price * quantity
  end

  def mark_as_sold!
    update(status: :sold, sold_at: Time.current)
  end

  def renew!(days = 30)
    update(expiry_date: Date.today + days.days, status: :active)
  end

  private

  def set_expiry_date
    self.expiry_date ||= Date.today + 30.days
  end
end
