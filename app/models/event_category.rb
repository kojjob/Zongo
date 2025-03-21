class EventCategory < ApplicationRecord
  belongs_to :parent_category, class_name: "EventCategory", optional: true
  has_many :subcategories, class_name: "EventCategory", foreign_key: "parent_category_id", dependent: :nullify
  has_many :events, dependent: :nullify

  # Validations
  validates :name, presence: true, uniqueness: { scope: :parent_category_id }

  # Scopes
  scope :root_categories, -> { where(parent_category_id: nil) }
  scope :subcategories_of, ->(parent_id) { where(parent_category_id: parent_id) }

  # Methods
  def root?
    parent_category_id.nil?
  end

  def has_events?
    events.exists?
  end

  def has_subcategories?
    subcategories.exists?
  end

  def all_subcategories
    subcategories.flat_map do |subcat|
      [ subcat ] + subcat.all_subcategories
    end
  end

  def ancestry
    result = []
    current = self

    while current.parent_category
      result.unshift(current.parent_category)
      current = current.parent_category
    end

    result
  end

  def full_name
    ancestry.map(&:name).push(name).join(" > ")
  end
end
