class Setting < ApplicationRecord
  # Validations
  validates :key, presence: true, uniqueness: true

  # Active Storage attachment for images
  has_one_attached :image

  # Helper class methods
  class << self
    # Get a setting value by key
    def get(key)
      setting = find_by(key: key)
      setting&.value
    end

    # Set a setting value by key
    def set(key, value)
      setting = find_or_initialize_by(key: key)
      setting.value = value
      setting.save
    end

    # Check if a setting exists
    def exists?(key)
      exists?(key: key)
    end
  end
end
