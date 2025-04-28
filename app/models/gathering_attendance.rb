class GatheringAttendance < ApplicationRecord
  belongs_to :user
  belongs_to :gathering, counter_cache: :attendees_count

  validates :user_id, uniqueness: { scope: :gathering_id }

  enum :status, { attending: 0, maybe: 1, not_attending: 2 }
end
