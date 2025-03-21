class Event < ApplicationRecord
  belongs_to :organizer, class_name: 'User', optional: true
  belongs_to :event_category, optional: true
  belongs_to :venue, optional: true
  belongs_to :parent_event, optional: true, class_name: 'Event'
  
  # Associations with dependent models
  has_many :ticket_types, dependent: :destroy
  has_many :event_tickets, dependent: :restrict_with_error
  has_many :attendances, dependent: :destroy
  has_many :event_favorites, dependent: :destroy
  has_many :event_comments, dependent: :destroy
  has_many :event_media, dependent: :destroy
  has_many :child_events, class_name: 'Event', foreign_key: 'parent_event_id', dependent: :nullify
  
  # Users who favorited this event
  has_many :favorited_by_users, through: :event_favorites, source: :user
  
  # Validations
  validates :title, presence: true
  validates :short_description, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :capacity, numericality: { greater_than_or_equal_to: 0 }
  validate :end_time_after_start_time
  
  # Status enum
  enum :status, {
    draft: 0,
    published: 1,
    cancelled: 2,
    postponed: 3,
    completed: 4
  }
  
  # Scopes
  scope :published, -> { where(status: :published) }
  scope :upcoming, -> { where('start_time > ?', Time.current).published }
  scope :past, -> { where('end_time < ?', Time.current).published }
  scope :ongoing, -> { where('start_time <= ? AND end_time >= ?', Time.current, Time.current).published }
  scope :featured, -> { where(is_featured: true) }
  scope :public_events, -> { where(is_private: false) }
  scope :by_category, ->(category_id) { where(event_category_id: category_id) }
  scope :by_organizer, ->(organizer_id) { where(organizer_id: organizer_id) }
  scope :by_venue, ->(venue_id) { where(venue_id: venue_id) }
  
  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? }
  before_save :update_status_based_on_time, if: -> { published? }
  
  # Methods
  
  # Get all media attached to this event
  def event_media_items
    event_media.ordered
  end
  
  # Get featured images
  def featured_images
    event_media.images.featured
  end
  
  # Get the first image for display
  def primary_image
    featured_images.first || event_media.images.first
  end
  
  # Check if the event has started
  def started?
    start_time <= Time.current
  end
  
  # Check if the event has ended
  def ended?
    end_time < Time.current
  end
  
  # Check if the event is ongoing
  def ongoing?
    started? && !ended?
  end
  
  # Get the event duration in hours
  def duration_hours
    ((end_time - start_time) / 1.hour).round(1)
  end
  
  # Check if the event is sold out
  def sold_out?
    return false if capacity.nil? || capacity.zero?
    attendances.confirmed_or_checked_in.count >= capacity
  end
  
  # Get the number of available spots
  def available_spots
    return nil if capacity.nil?
    [capacity - attendances.confirmed_or_checked_in.count, 0].max
  end
  
  # Get registration percentage
  def registration_percentage
    return 0 if capacity.nil? || capacity.zero?
    [(attendances.confirmed_or_checked_in.count.to_f / capacity) * 100, 100].min.round
  end
  
  # Format date and time for display
  def formatted_date
    start_time.strftime("%B %d, %Y")
  end
  
  def formatted_time_range
    same_day = start_time.to_date == end_time.to_date
    
    if same_day
      "#{start_time.strftime("%I:%M %p")} - #{end_time.strftime("%I:%M %p")}"
    else
      "#{start_time.strftime("%b %d, %I:%M %p")} - #{end_time.strftime("%b %d, %I:%M %p")}"
    end
  end
  
  # Add a view to the counter
  def increment_view_count!
    increment!(:views_count)
  end
  
  # Add a comment
  def add_comment(user, content, parent_comment_id = nil)
    event_comments.create(
      user: user,
      content: content,
      parent_comment_id: parent_comment_id
    )
  end
  
  # Find related events
  def related_events(limit = 3)
    Event.published
         .where.not(id: id)
         .where(event_category_id: event_category_id)
         .order(start_time: :asc)
         .limit(limit)
  end
  
  private
  
  def end_time_after_start_time
    return if start_time.nil? || end_time.nil?
    
    if end_time <= start_time
      errors.add(:end_time, "must be after start time")
    end
  end
  
  def generate_slug
    base_slug = title.parameterize
    unique_slug = base_slug
    counter = 2
    
    while Event.exists?(slug: unique_slug)
      unique_slug = "#{base_slug}-#{counter}"
      counter += 1
    end
    
    self.slug = unique_slug
  end
  
  def update_status_based_on_time
    if end_time < Time.current
      self.status = :completed
    end
  end
  
  def set_defaults
    self.views_count ||= 0
    self.favorites_count ||= 0
    self.status ||= :draft # Default to draft status
    self.is_featured ||= false
    self.is_private ||= false
  end
end
