class CreditScore < ApplicationRecord
  belongs_to :user

  validates :score, presence: true, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 300,
    less_than_or_equal_to: 850
  }
  validates :calculated_at, presence: true

  before_save :ensure_single_current_score, if: :can_be_current?

  # Only use is_current if the column exists
  scope :current, -> {
    if column_names.include?("is_current")
      where(is_current: true)
    else
      order(created_at: :desc).limit(1)
    end
  }

  private

  def can_be_current?
    self.class.column_names.include?("is_current") && is_current?
  end

  def ensure_single_current_score
    if self.class.column_names.include?("is_current")
      user.credit_scores.where.not(id: id).update_all(is_current: false)
    end
  end
end
