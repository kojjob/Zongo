json.extract! venue, :id, :name, :description, :address, :city, :region, :postal_code, :country, :latitude, :longitude, :capacity, :user_id, :facilities, :created_at, :updated_at
json.url venue_url(venue, format: :json)
