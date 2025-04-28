class Group < ApplicationRecord
  belongs_to :group_category, counter_cache: :groups_count
  has_many :group_memberships
  has_many :users, through: :group_memberships
  has_many :gatherings
  
  validates :name, presence: true
  validates :description, presence: true
  
  scope :featured, -> { where(featured: true) }
  scope :popular, -> { order(members_count: :desc) }
  
  def self.search(query)
    where("name ILIKE ? OR description ILIKE ?", "%#{query}%", "%#{query}%")
  end
end
