json.extract! event, :id, :title, :description, :short_description, :start_time, :end_time, :capacity, :status, :is_featured, :is_private, :access_code, :slug, :organizer_id, :event_category_id, :venue_id, :recurrence_type, :recurrence_pattern, :parent_event_id, :favorites_count, :views_count, :custom_fields, :created_at, :updated_at
json.url event_url(event, format: :json)
