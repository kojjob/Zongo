class GroupMembership < ApplicationRecord
  belongs_to :user
  belongs_to :group, counter_cache: :members_count

  validates :user_id, uniqueness: { scope: :group_id }

  enum :role, { member: 0, moderator: 1, admin: 2 }
end
