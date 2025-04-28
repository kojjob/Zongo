class PromotionalBanner < ApplicationRecord
  # Associations
  belongs_to :shop_category, optional: true
  has_one_attached :image
  
  # Validations
  validates :title, presence: true
  validates :location, presence: true
  validate :valid_date_range
  validate :valid_colors
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :current, -> { active.where('starts_at IS NULL OR starts_at <= ?', Time.current).where('ends_at IS NULL OR ends_at >= ?', Time.current) }
  scope :by_location, ->(location) { where(location: location) }
  scope :by_category, ->(category_id) { where(shop_category_id: category_id) }
  scope :ordered, -> { order(position: :asc) }
  
  # Methods
  def active?
    return false unless self.active
    
    current_time = Time.current
    start_condition = starts_at.nil? || starts_at <= current_time
    end_condition = ends_at.nil? || ends_at >= current_time
    
    start_condition && end_condition
  end
  
  def expired?
    ends_at.present? && ends_at < Time.current
  end
  
  def has_button?
    button_text.present? && link_url.present?
  end
  
  def has_image?
    image.attached?
  end
  
  private
  
  def valid_date_range
    return if starts_at.nil? || ends_at.nil?
    
    if starts_at >= ends_at
      errors.add(:ends_at, "must be after the start date")
    end
  end
  
  def valid_colors
    color_fields = [:background_color, :text_color, :button_color, :button_text_color]
    
    color_fields.each do |field|
      value = self.send(field)
      next if value.blank?
      
      unless value.match(/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/)
        errors.add(field, "must be a valid hex color code (e.g., #FF0000)")
      end
    end
  end
end
