class Venue < ApplicationRecord
  has_many :events, dependent: :nullify
  belongs_to :user, optional: true

  validates :name, presence: true
  validates :phone, format: { with: /\A\+?[0-9\s\-\.\(\)]+\z/, allow_blank: true }, length: { maximum: 20 }
  validates :website, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), allow_blank: true }

  # Geocoding functionality - Uncomment after installing the geocoder gem
  # geocoded_by :full_address
  # after_validation :geocode, if: ->(obj) { obj.full_address.present? && (obj.latitude.blank? || obj.longitude.blank? || obj.address_changed? || obj.city_changed? || obj.state_changed? || obj.country_changed? || obj.postal_code_changed?) }

  def full_address
    [ address, city, state, country, postal_code ].compact.join(", ")
  end

  def address_changed?
    saved_change_to_address?
  end

  def city_changed?
    saved_change_to_city?
  end

  def state_changed?
    saved_change_to_state?
  end

  def country_changed?
    saved_change_to_country?
  end

  def postal_code_changed?
    saved_change_to_postal_code?
  end

  def display_name
    name
  end

  def display_address
    [ address, city, state, country ].compact.join(", ")
  end

  def formatted_phone
    return nil unless phone.present?
    phone.gsub(/\A\+?233/, "0") # Convert Ghanaian international format to local
  end
end
