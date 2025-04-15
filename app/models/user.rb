class User < ApplicationRecord
  # Include Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Active Storage attachment
  has_one_attached :avatar

  # Add custom serialization methods to fix the issue
  def self.serialize_from_session(key, salt)
    record = find_by(id: key[0])
    record if record && record.authenticatable_salt == salt
  end

  def authenticatable_salt
    "#{self.class.salt}#{super}"
  rescue
    "#{self.class.salt}--#{created_at}--#{id}"
  end

  # The salt used for serialization
  def self.salt
    "authenticated-devise-user"
  end

  # Associations
  has_one :wallet, dependent: :destroy
  has_many :payment_methods, dependent: :destroy
  has_many :organized_events, class_name: "Event", foreign_key: "organizer_id", dependent: :nullify
  has_many :attendances, dependent: :destroy
  has_many :attending_events, through: :attendances, source: :event
  has_many :comments, dependent: :nullify
  has_many :favorites, dependent: :destroy

  # Notifications methods
  def unread_notifications_count
    # This is a placeholder method that should be replaced with actual notification logic
    # For now, we'll return 0 to avoid errors
    0
  end

  # Event-related methods
  def attending?(event)
    attending_events.include?(event)
  end

  def favorited?(favoritable)
    return false unless favoritable

    # Handle the case where favorites table might not exist yet
    begin
      favorites.exists?(favoritable: favoritable)
    rescue ActiveRecord::StatementInvalid => e
      if e.message.include?('relation "favorites" does not exist')
        # Check if we can find an event_favorite record instead
        return EventFavorite.exists?(user_id: id, event_id: favoritable.id) if favoritable.is_a?(Event) && defined?(EventFavorite)
        false
      else
        raise e
      end
    end
  end

  def has_favorite_events?
    begin
      favorites.where(favoritable_type: "Event").exists?
    rescue ActiveRecord::StatementInvalid => e
      if e.message.include?('relation "favorites" does not exist')
        # Check if we can find event_favorite records instead
        return EventFavorite.exists?(user_id: id) if defined?(EventFavorite)
        false
      else
        raise e
      end
    end
  end

  def favorite_events
    begin
      Event.joins(:favorites).where(favorites: { user_id: id, favoritable_type: "Event" })
    rescue ActiveRecord::StatementInvalid => e
      if e.message.include?('relation "favorites" does not exist')
        # Fallback to using event_favorites
        return Event.joins(:event_favorites).where(event_favorites: { user_id: id }) if defined?(EventFavorite) && Event.respond_to?(:joins) && Event.method(:joins).arity != 0
        Event.none
      else
        raise e
      end
    end
  end

  def attend_event!(event)
    attendances.create!(event: event)
  end

  def cancel_attendance!(event)
    attendances.find_by(event: event)&.destroy
  end

  def toggle_favorite!(favoritable)
    return false unless favoritable

    # Handle the case where favorites table might not exist yet
    begin
      favorite = favorites.find_by(favoritable: favoritable)

      if favorite
        favorite.destroy
        false
      else
        favorites.create!(favoritable: favoritable)
        true
      end
    rescue ActiveRecord::StatementInvalid => e
      if e.message.include?('relation "favorites" does not exist')
        # If it's an event, use event_favorites as a fallback
        if favoritable.is_a?(Event) && defined?(EventFavorite)
          event_favorite = EventFavorite.find_by(user_id: id, event_id: favoritable.id)
          if event_favorite
            event_favorite.destroy
            false
          else
            EventFavorite.create!(user_id: id, event_id: favoritable.id)
            true
          end
        else
          false # Can't toggle favorites for other types if table doesn't exist
        end
      else
        raise e
      end
    end
  end

  # Profile image placeholder method - customize based on your implementation
  def profile_image
    # This is a placeholder method
    OpenStruct.new(url: "/assets/images/default-avatar.jpg")
  end

  def full_name
    # Use username, email, or a default when name isn't available
    username.presence || email.split('@').first || "Anonymous User"
  end

  def first_name
    # Use the first part of the full name or username
    full_name.split(" ").first
  end

  def last_name
    # Use the last part of the full name or blank if not available
    parts = full_name.split(" ")
    parts.length > 1 ? parts.last : ""
  end

  def initials
    first = first_name.to_s[0] || ''
    last = last_name.to_s[0] || ''

    if first.present? || last.present?
      "#{first}#{last}".upcase
    else
      "U"
    end
  end

  # Check if user is an admin
  def admin?
    respond_to?(:admin) && admin == true
  end
end