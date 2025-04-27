class ShopCategory < ApplicationRecord
  # Associations
  has_many :products, dependent: :nullify
  belongs_to :parent, class_name: "ShopCategory", optional: true
  has_many :subcategories, class_name: "ShopCategory", foreign_key: "parent_id", dependent: :nullify

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  
  # Callbacks
  before_validation :generate_slug, if: -> { name.present? && slug.blank? }
  
  # Scopes
  scope :root_categories, -> { where(parent_id: nil) }
  scope :featured, -> { where(featured: true) }
  scope :active, -> { where(active: true) }
  
  # Default categories for seeding
  DEFAULTS = [
    { name: "Electronics", icon: "device-mobile", color_code: "#3B82F6", description: "Phones, computers, and accessories" },
    { name: "Fashion", icon: "shirt", color_code: "#8B5CF6", description: "Clothing, shoes, and accessories" },
    { name: "Home & Garden", icon: "home", color_code: "#10B981", description: "Furniture, decor, and garden supplies" },
    { name: "Beauty & Health", icon: "heart", color_code: "#EC4899", description: "Cosmetics, personal care, and wellness products" },
    { name: "Groceries", icon: "shopping-cart", color_code: "#F59E0B", description: "Food, beverages, and household essentials" },
    { name: "Sports & Outdoors", icon: "activity", color_code: "#3B82F6", description: "Sports equipment, outdoor gear, and fitness products" },
    { name: "Books & Media", icon: "book-open", color_code: "#EF4444", description: "Books, music, movies, and games" },
    { name: "Toys & Kids", icon: "gift", color_code: "#8B5CF6", description: "Toys, baby products, and children's items" }
  ]
  
  # Methods
  def to_param
    slug
  end
  
  def has_subcategories?
    subcategories.exists?
  end
  
  def all_products
    if has_subcategories?
      Product.where(shop_category_id: [id] + subcategories.pluck(:id))
    else
      products
    end
  end
  
  private
  
  def generate_slug
    self.slug = name.parameterize
  end
end
