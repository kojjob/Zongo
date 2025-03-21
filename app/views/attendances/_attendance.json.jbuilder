json.extract! attendance, :id, :user_id, :event_id, :status, :checked_in_at, :cancelled_at, :additional_info, :form_responses, :created_at, :updated_at
json.url attendance_url(attendance, format: :json)
