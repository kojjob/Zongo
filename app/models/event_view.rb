class EventView < ApplicationRecord
  belongs_to :event, counter_cache: :views_count
  belongs_to :user, optional: true

  validates :event_id, presence: true
  validates :ip_address, presence: true

  scope :today, -> { where("created_at >= ?", Date.today.beginning_of_day) }
  scope :yesterday, -> { where(created_at: 1.day.ago.beginning_of_day..1.day.ago.end_of_day) }
  scope :this_week, -> { where("created_at >= ?", 1.week.ago.beginning_of_day) }
  scope :last_week, -> { where(created_at: 2.weeks.ago.beginning_of_day..1.week.ago.end_of_day) }
  scope :this_month, -> { where("created_at >= ?", 1.month.ago.beginning_of_day) }
  scope :by_hour, -> { group_by_hour(:created_at, range: 24.hours.ago..Time.now) }
  scope :by_day, -> { group_by_day(:created_at, range: 30.days.ago..Time.now) }
  scope :by_device_type, -> { group(:device_type).count }
  scope :unique_viewers, -> { select(:ip_address).distinct.count }

  # Prevent duplicate views from the same user/IP in a short time period
  def self.register(event_id, ip_address, user_id = nil, user_agent = nil, referer = nil)
    existing = where(event_id: event_id)
    existing = existing.where(user_id: user_id) if user_id
    existing = existing.where(ip_address: ip_address) if ip_address
    existing = existing.where("created_at > ?", 6.hours.ago)

    return false if existing.exists?

    # Check which column exists for storing referrer
    has_referer = column_names.include?("referer")
    has_referrer = column_names.include?("referrer")

    attributes = {
      event_id: event_id,
      user_id: user_id,
      ip_address: ip_address,
      user_agent: user_agent
    }

    # Add viewed_at if the column exists
    attributes[:viewed_at] = Time.current if column_names.include?("viewed_at")

    # Add referrer to the appropriate column
    if has_referer
      attributes[:referer] = referer
    elsif has_referrer
      attributes[:referrer] = referer
    end

    create(attributes)
  end

  # Calculate unique viewers for an event
  def self.unique_viewers_for_event(event_id)
    where(event_id: event_id).select(:ip_address).distinct.count
  end

  # Get view count by date for an event
  def self.views_by_date(event_id, days = 30)
    where(event_id: event_id)
      .where("created_at >= ?", days.days.ago)
      .group("DATE(created_at)")
      .count
  end

  # Detect device type from user agent
  def device_type
    return "unknown" if user_agent.blank?

    ua = user_agent.downcase
    if ua.match?(/mobile|android|iphone|ipad|ipod/i)
      "mobile"
    elsif ua.match?(/tablet|ipad/i)
      "tablet"
    else
      "desktop"
    end
  end

  # Get source of traffic
  def source
    # Handle either column name (referer or referrer)
    referrer_url = self.try(:referer) || self.try(:referrer) || ""
    return "direct" if referrer_url.blank?

    uri = URI.parse(referrer_url) rescue nil
    return "unknown" if uri.nil?

    host = uri.host.downcase rescue "unknown"

    case host
    when /google/
      "google"
    when /facebook/
      "facebook"
    when /twitter|x\.com/
      "twitter"
    when /instagram/
      "instagram"
    when /linkedin/
      "linkedin"
    else
      host
    end
  end
end
