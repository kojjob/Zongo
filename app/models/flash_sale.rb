class FlashSale < ApplicationRecord
  # Associations
  has_many :flash_sale_items, dependent: :destroy
  has_many :products, through: :flash_sale_items
  
  # Validations
  validates :name, presence: true
  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validate :valid_date_range
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :current, -> { active.where('starts_at <= ? AND ends_at >= ?', Time.current, Time.current) }
  scope :upcoming, -> { active.where('starts_at > ?', Time.current) }
  scope :past, -> { where('ends_at < ?', Time.current) }
  scope :featured, -> { where(featured: true) }
  
  # Methods
  def active?
    return false unless self.active
    
    current_time = Time.current
    starts_at <= current_time && ends_at >= current_time
  end
  
  def upcoming?
    self.active && starts_at > Time.current
  end
  
  def expired?
    ends_at < Time.current
  end
  
  def time_remaining
    return nil if expired?
    
    if upcoming?
      # Time until the sale starts
      (starts_at - Time.current).to_i
    else
      # Time until the sale ends
      (ends_at - Time.current).to_i
    end
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
  
  def seconds_remaining
    return nil unless time_remaining
    
    time_remaining
  end
  
  def progress_percentage
    return 0 if upcoming?
    return 100 if expired?
    
    total_duration = (ends_at - starts_at).to_i
    elapsed_time = (Time.current - starts_at).to_i
    
    [(elapsed_time.to_f / total_duration * 100).round, 100].min
  end
  
  def add_product(product, discount_value, discount_type = 'percentage', quantity_limit = nil)
    flash_sale_items.create(
      product: product,
      discount_value: discount_value,
      discount_type: discount_type,
      quantity_limit: quantity_limit
    )
  end
  
  private
  
  def valid_date_range
    if starts_at.present? && ends_at.present? && starts_at >= ends_at
      errors.add(:ends_at, "must be after the start date")
    end
  end
end
