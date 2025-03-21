class Event < ApplicationRecord
  belongs_to :organizer
  belongs_to :event_category
  belongs_to :venue
  belongs_to :parent_event
end
