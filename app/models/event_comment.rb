class EventComment < ApplicationRecord
  belongs_to :event
  belongs_to :user
  belongs_to :parent_comment
end
