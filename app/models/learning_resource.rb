class LearningResource < ApplicationRecord
  belongs_to :resource_category, counter_cache: :resources_count
  
  validates :title, presence: true
  validates :description, presence: true
  validates :file_url, presence: true
  
  scope :featured, -> { where(featured: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :popular, -> { order(downloads_count: :desc) }
  
  def self.search(query)
    where("title ILIKE ? OR description ILIKE ?", "%#{query}%", "%#{query}%")
  end
end
