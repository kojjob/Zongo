class DigitalDownload < ApplicationRecord
  belongs_to :user
  belongs_to :product
  belongs_to :order_item
  
  validates :user_id, presence: true
  validates :product_id, presence: true
  validates :order_item_id, presence: true
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_product, ->(product_id) { where(product_id: product_id) }
  
  # Methods
  def self.download_count_for_user_and_product(user_id, product_id)
    where(user_id: user_id, product_id: product_id).count
  end
end
