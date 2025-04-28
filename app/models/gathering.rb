class Gathering < ApplicationRecord
  belongs_to :group, optional: true
  belongs_to :organizer, class_name: 'User'
  has_many :gathering_attendances
  has_many :attendees, through: :gathering_attendances, source: :user
  
  validates :title, presence: true
  validates :description, presence: true
  validates :date, presence: true
  validates :location, presence: true
  
  scope :upcoming, -> { where("date >= ?", Date.today).order(date: :asc) }
  scope :past, -> { where("date < ?", Date.today).order(date: :desc) }
  scope :featured, -> { where(featured: true) }
  
  def self.search(query)
    where("title ILIKE ? OR description ILIKE ?", "%#{query}%", "%#{query}%")
  end
end
