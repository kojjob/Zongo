json.extract! event_medium, :id, :event_id, :user_id, :media_type, :title, :description, :is_featured, :display_order, :created_at, :updated_at
json.url event_medium_url(event_medium, format: :json)
