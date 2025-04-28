class GroupCategory < ApplicationRecord
  has_many :groups
  
  validates :name, presence: true, uniqueness: true
end
