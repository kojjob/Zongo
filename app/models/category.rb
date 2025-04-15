class Category < ApplicationRecord
  has_many :events, dependent: :nullify

  validates :name, presence: true, uniqueness: true

  # Default categories for seeding
  DEFAULTS = [
    { name: "Music & Art", icon: "music", color_code: "#8B5CF6" },
    { name: "Sports", icon: "activity", color_code: "#3B82F6" },
    { name: "Food & Drink", icon: "utensils", color_code: "#F59E0B" },
    { name: "Technology", icon: "code", color_code: "#10B981" },
    { name: "Business", icon: "briefcase", color_code: "#6B7280" },
    { name: "Education", icon: "book-open", color_code: "#EF4444" },
    { name: "Community", icon: "users", color_code: "#EC4899" },
    { name: "Health & Wellness", icon: "heart", color_code: "#14B8A6" }
  ]

  def self.seed_defaults
    DEFAULTS.each do |category_data|
      find_or_create_by!(name: category_data[:name]) do |category|
        category.icon = category_data[:icon]
        category.color_code = category_data[:color_code]
      end
    end
  end
end
