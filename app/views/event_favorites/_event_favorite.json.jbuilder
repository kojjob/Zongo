json.extract! event_favorite, :id, :event_id, :user_id, :created_at, :updated_at
json.url event_favorite_url(event_favorite, format: :json)
