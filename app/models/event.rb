class Event < ApplicationRecord
  # Associations
  belongs_to :organizer, class_name: "User"
  belongs_to :venue, optional: true
  belongs_to :category, optional: true

  has_many :attendances, dependent: :destroy
  has_many :attendees, through: :attendances, source: :user
  has_many :event_comments, dependent: :destroy
  has_many :event_media, dependent: :destroy
  has_many :event_views, dependent: :destroy
  has_many :event_favorites, dependent: :destroy
  has_many :favorites, as: :favoritable, dependent: :destroy

  # Validations
  validates :title, presence: true, length: { minimum: 5, maximum: 255 }
  validates :description, presence: true
  validates :short_description, length: { maximum: 500 }
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :capacity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :end_time_after_start_time
  validate :start_time_not_in_past, on: :create
  validates :slug, presence: true, uniqueness: true

  # Callbacks
  before_validation :set_slug, if: -> { slug.blank? }
  before_validation :ensure_short_description
  scope :upcoming, -> { where("start_time > ?", Time.current).order(start_time: :asc) }
  scope :past, -> { where("end_time < ?", Time.current).order(start_time: :desc) }
  scope :ongoing, -> { where("start_time <= ? AND end_time >= ?", Time.current, Time.current) }
  scope :this_weekend, -> {
    where(start_time: (Time.current.end_of_week - 2.days)..Time.current.end_of_week)
    .order(start_time: :asc)
  }
  scope :featured, -> { where(is_featured: true) }
  scope :by_category, ->(category_id) { category_id.present? ? where(category_id: category_id) : none }
  scope :free, -> { where("price <= 0 OR price IS NULL") }
  scope :paid, -> { where("price > 0") }

  # Value object for price
  def ticket_price
    price.present? ? "₵#{sprintf('%.2f', price)}" : "Free"
  end

  def free?
    price.nil? || price <= 0
  end

  # Domain logic
  def sold_out?
    capacity.present? && attendances.count >= capacity
  end

  def upcoming?
    start_time > Time.current
  end

  def ongoing?
    start_time <= Time.current && end_time >= Time.current
  end

  def past?
    end_time < Time.current
  end

  def can_attend?(user)
    return false unless user
    upcoming? && !sold_out? && !attendees.include?(user)
  end

  def attending?(user)
    return false unless user
    attendances.exists?(user_id: user.id)
  end

  def favorited_by?(user)
    return false unless user
    
    # Handle the case where favorites table might not exist yet
    begin
      favorites.exists?(user_id: user.id)
    rescue ActiveRecord::StatementInvalid => e
      if e.message.include?('relation "favorites" does not exist')
        # Check if we can find an event_favorite record instead
        return event_favorites.exists?(user_id: user.id) if defined?(EventFavorite) && respond_to?(:event_favorites)
        false
      else
        raise e
      end
    end
  end

  # Display helpers
  def status_badge
    if upcoming?
      "Upcoming"
    elsif ongoing?
      "Happening Now"
    else
      "Past"
    end
  end

  def status_color
    if upcoming?
      "blue"
    elsif ongoing?
      "green"
    else
      "gray"
    end
  end

  def featured_image
    event_media.find_by(is_featured: true) || event_media.first
  end

  private

  def end_time_after_start_time
    return if end_time.blank? || start_time.blank?

    if end_time <= start_time
      errors.add(:end_time, "must be after start time")
    end
  end
  
  def start_time_not_in_past
    return if start_time.blank?

    if start_time < Time.current
      errors.add(:start_time, "can't be in the past")
    end
  end
  
  def set_slug
    base_slug = title.to_s.parameterize
    unique_slug = base_slug
    counter = 2
    
    # Generate a unique slug
    while Event.where(slug: unique_slug).exists?
      unique_slug = "#{base_slug}-#{counter}"
      counter += 1
    end
    
    self.slug = unique_slug
  end
  
  def ensure_short_description
    return if short_description.present?
    
    # Generate a short description from the full description
    if description.present?
      self.short_description = description.truncate(200, separator: ' ', omission: '...')
    end
  end
  
  # Calendar integration helpers
  
  # Returns the URL for the event
  def event_url_for_calendar
    Rails.application.routes.url_helpers.event_url(self, host: Rails.application.config.action_mailer.default_url_options&.fetch(:host) || 'zongo.app')
  end
  
  # Returns the event formatted for calendar exports
  def to_ical
    calendar = Icalendar::Calendar.new
    calendar.prodid = '-//Zongo//Events Calendar//EN'
    
    event = Icalendar::Event.new
    event.dtstart = Icalendar::Values::DateTime.new(start_time.utc, tzid: 'UTC')
    event.dtend = Icalendar::Values::DateTime.new(end_time.utc, tzid: 'UTC')
    event.summary = title
    event.description = "#{short_description}\n\n#{event_url_for_calendar}"
    event.location = [venue&.name, venue&.address].compact.join(', ')
    event.url = event_url_for_calendar
    event.uid = "#{id}@zongo.app"
    
    calendar.add_event(event)
    calendar.to_ical
  end
  
  # Returns formatted location for calendar services
  def formatted_location
    [venue&.name, venue&.address].compact.join(', ')
  end
end
