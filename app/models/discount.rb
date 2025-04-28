class Discount < ApplicationRecord
  # Associations
  belongs_to :shop_category, optional: true
  belongs_to :product, optional: true
  
  # Validations
  validates :name, presence: true
  validates :value, presence: true, numericality: { greater_than: 0 }
  validates :discount_type, presence: true, inclusion: { in: %w[percentage fixed_amount] }
  validate :valid_date_range
  validate :category_or_product_present
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :current, -> { active.where('starts_at IS NULL OR starts_at <= ?', Time.current).where('ends_at IS NULL OR ends_at >= ?', Time.current) }
  scope :featured, -> { where(featured: true) }
  scope :by_category, ->(category_id) { where(shop_category_id: category_id) }
  scope :by_product, ->(product_id) { where(product_id: product_id) }
  scope :percentage_discounts, -> { where(discount_type: 'percentage') }
  scope :fixed_amount_discounts, -> { where(discount_type: 'fixed_amount') }
  
  # Methods
  def active?
    return false unless self.active
    
    current_time = Time.current
    start_condition = starts_at.nil? || starts_at <= current_time
    end_condition = ends_at.nil? || ends_at >= current_time
    usage_condition = usage_limit.nil? || usage_count < usage_limit
    
    start_condition && end_condition && usage_condition
  end
  
  def expired?
    ends_at.present? && ends_at < Time.current
  end
  
  def usage_limit_reached?
    usage_limit.present? && usage_count >= usage_limit
  end
  
  def increment_usage!
    return false if usage_limit_reached?
    
    self.increment!(:usage_count)
  end
  
  def calculate_discount_amount(original_price)
    return 0 unless active?
    
    if discount_type == 'percentage'
      (original_price * (value / 100.0)).round(2)
    else
      [value, original_price].min # Don't discount more than the original price
    end
  end
  
  def formatted_discount
    if discount_type == 'percentage'
      "#{value.to_i}% off"
    else
      "GHS #{value} off"
    end
  end
  
  def time_remaining
    return nil if ends_at.nil?
    return nil if expired?
    
    (ends_at - Time.current).to_i
  end
  
  def days_remaining
    return nil unless time_remaining
    
    (time_remaining / 1.day).to_i
  end
  
  def hours_remaining
    return nil unless time_remaining
    
    (time_remaining / 1.hour).to_i
  end
  
  def minutes_remaining
    return nil unless time_remaining
    
    (time_remaining / 1.minute).to_i
  end
  
  private
  
  def valid_date_range
    return if starts_at.nil? || ends_at.nil?
    
    if starts_at >= ends_at
      errors.add(:ends_at, "must be after the start date")
    end
  end
  
  def category_or_product_present
    if shop_category_id.blank? && product_id.blank?
      errors.add(:base, "Either a category or a product must be specified")
    end
  end
end
