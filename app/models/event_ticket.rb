class EventTicket < ApplicationRecord
  belongs_to :user
  belongs_to :event
  belongs_to :ticket_type
  belongs_to :attendance
end
