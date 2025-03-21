class EventFavorite < ApplicationRecord
  belongs_to :event
  belongs_to :user
  
  # Validations
  validates :user_id, uniqueness: { scope: :event_id, message: "has already favorited this event" }
  
  # Callbacks
  after_create :increment_event_favorites_count
  after_destroy :decrement_event_favorites_count
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_event, ->(event_id) { where(event_id: event_id) }
  
  private
  
  def increment_event_favorites_count
    Event.increment_counter(:favorites_count, event_id)
  end
  
  def decrement_event_favorites_count
    Event.decrement_counter(:favorites_count, event_id)
  end
end
