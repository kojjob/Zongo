class ResourceCategory < ApplicationRecord
  has_many :learning_resources
  
  validates :name, presence: true, uniqueness: true
end
