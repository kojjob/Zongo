class SearchQuery < ApplicationRecord
  # Associations
  belongs_to :user, optional: true
  
  # Validations
  validates :query, presence: true
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :popular, -> { group(:query).order('COUNT(id) DESC') }
  scope :with_results, -> { where('results_count > 0') }
  scope :without_results, -> { where(results_count: 0) }
  
  # Class methods
  def self.top_searches(limit = 10)
    popular.limit(limit)
  end
  
  def self.trending_searches(days = 7, limit = 10)
    where('created_at >= ?', days.days.ago)
      .group(:query)
      .order('COUNT(id) DESC')
      .limit(limit)
  end
  
  def self.zero_results_searches(limit = 10)
    without_results
      .group(:query)
      .order('COUNT(id) DESC')
      .limit(limit)
  end
end
