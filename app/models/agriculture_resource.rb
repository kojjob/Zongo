class AgricultureResource < ApplicationRecord
  # Associations
  belongs_to :crop, optional: true
  belongs_to :user, optional: true # For user-contributed resources

  # Validations
  validates :title, presence: true
  validates :content, presence: true
  validates :resource_type, presence: true

  # Enums
  enum :resource_type, {
    article: 0,
    video: 1,
    guide: 2,
    tool: 3,
    faq: 4,
    pest_disease: 5
  }

  # Active Storage
  has_one_attached :thumbnail
  has_one_attached :document
  has_many_attached :images

  # Scopes
  scope :published, -> { where(published: true) }
  scope :featured, -> { where(featured: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :popular, -> { order(view_count: :desc) }
  scope :by_crop, ->(crop_id) { where(crop_id: crop_id) }
  scope :by_type, ->(type) { where(resource_type: type) }

  # Search scope
  scope :search, ->(query) {
    where("title ILIKE ? OR content ILIKE ? OR tags ILIKE ?",
          "%#{query}%", "%#{query}%", "%#{query}%")
  }

  # Methods
  def increment_view_count!
    update(view_count: view_count + 1)
  end

  def related_resources(limit = 5)
    return [] unless crop_id.present?

    AgricultureResource.published
                       .where(crop_id: crop_id)
                       .where.not(id: id)
                       .limit(limit)
  end

  def reading_time
    # Estimate reading time based on content length
    # Average reading speed: 200 words per minute
    word_count = content.split.size
    minutes = (word_count / 200.0).ceil
    minutes = 1 if minutes < 1
    minutes
  end

  def tag_list
    tags.split(',').map(&:strip) if tags.present?
  end

  def tag_list=(tags_array)
    self.tags = tags_array.join(',')
  end

  def publish!
    update(published: true, published_at: Time.current)
  end

  def unpublish!
    update(published: false, published_at: nil)
  end

  def feature!
    update(featured: true)
  end

  def unfeature!
    update(featured: false)
  end
end
