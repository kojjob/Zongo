class Review < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :product
  
  # Validations
  validates :rating, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  validates :comment, presence: true, length: { minimum: 10, maximum: 1000 }
  validates :user_id, uniqueness: { scope: :product_id, message: "has already reviewed this product" }
  validate :user_must_have_purchased_product
  
  # Scopes
  scope :approved, -> { where(approved: true) }
  scope :pending, -> { where(approved: false) }
  scope :recent, -> { order(created_at: :desc) }
  scope :highest_rated, -> { order(rating: :desc) }
  scope :lowest_rated, -> { order(rating: :asc) }
  
  # Methods
  def formatted_rating
    "#{rating}/5"
  end
  
  private
  
  def user_must_have_purchased_product
    unless user.orders.completed.joins(:order_items).where(order_items: { product_id: product_id }).exists?
      errors.add(:user, "must have purchased this product to leave a review")
    end
  end
end
