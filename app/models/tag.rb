class Tag < ApplicationRecord
  # Check if the tables exist before defining associations
  begin
    if ActiveRecord::Base.connection.table_exists?("event_tags")
      has_many :event_tags, dependent: :destroy
      has_many :events, through: :event_tags
    end
  rescue ActiveRecord::StatementInvalid => e
    # Tables don't exist yet, associations will be set up when migrations are run
  end

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :slug, presence: true, uniqueness: { case_sensitive: false }

  before_validation :generate_slug, if: -> { name.present? && slug.blank? }

  scope :popular, -> { order(events_count: :desc).limit(20) }
  scope :with_events, -> { where("events_count > 0") }

  def self.find_or_create_by_name(name)
    normalized_name = name.strip.downcase
    find_or_create_by(name: normalized_name) do |tag|
      tag.slug = normalized_name.parameterize
    end
  end

  # Class method to check if tag tables exist
  def self.tables_exist?
    ActiveRecord::Base.connection.table_exists?("tags") &&
    ActiveRecord::Base.connection.table_exists?("event_tags")
  rescue ActiveRecord::StatementInvalid => e
    false
  end

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
