class Coupon < ApplicationRecord
  # Associations
  belongs_to :shop_category, optional: true
  has_many :orders
  
  # Validations
  validates :code, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validates :value, presence: true, numericality: { greater_than: 0 }
  validates :discount_type, presence: true, inclusion: { in: %w[percentage fixed_amount] }
  validate :valid_date_range
  
  # Callbacks
  before_validation :normalize_code
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :current, -> { active.where('starts_at IS NULL OR starts_at <= ?', Time.current).where('ends_at IS NULL OR ends_at >= ?', Time.current) }
  scope :by_category, ->(category_id) { where(shop_category_id: category_id) }
  scope :percentage_coupons, -> { where(discount_type: 'percentage') }
  scope :fixed_amount_coupons, -> { where(discount_type: 'fixed_amount') }
  
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
  
  def valid_for_order?(order)
    return false unless active?
    return false if minimum_order_amount.present? && order.total_amount < minimum_order_amount
    return false if first_time_purchase_only && order.user.orders.completed.exists?
    return false if shop_category_id.present? && !order.order_items.joins(:product).where(products: { shop_category_id: shop_category_id }).exists?
    
    true
  end
  
  def calculate_discount_amount(order_total)
    return 0 unless active?
    
    if discount_type == 'percentage'
      (order_total * (value / 100.0)).round(2)
    else
      [value, order_total].min # Don't discount more than the order total
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
  
  def normalize_code
    self.code = code.upcase.strip if code.present?
  end
  
  def valid_date_range
    return if starts_at.nil? || ends_at.nil?
    
    if starts_at >= ends_at
      errors.add(:ends_at, "must be after the start date")
    end
  end
end
