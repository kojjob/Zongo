class NavigationItem < ApplicationRecord
  # Associations
  belongs_to :parent, class_name: 'NavigationItem', optional: true
  has_many :children, class_name: 'NavigationItem', foreign_key: 'parent_id', dependent: :destroy
  
  # Validations
  validates :title, presence: true
  validates :path, presence: true, unless: :has_children?
  
  # Scopes
  scope :root_items, -> { where(parent_id: nil) }
  scope :active, -> { where(active: true) }
  scope :by_position, -> { order(position: :asc) }
  
  # Class methods
  def self.visible_for(user)
    if user&.admin?
      active
    elsif user
      active.where('required_role IS NULL OR required_role <= ?', user.role)
    else
      active.where(required_role: nil)
    end
  end
  
  # Instance methods
  def has_children?
    children.exists?
  end
  
  def icon_class
    icon.presence || 'default-icon'
  end
  
  def requires_auth?
    required_role.present?
  end
  
  def visible_for?(user)
    return true unless requires_auth?
    return false unless user
    
    user.admin? || (user.role >= required_role)
  end
end
