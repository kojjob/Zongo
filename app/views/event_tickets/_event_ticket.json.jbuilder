json.extract! event_ticket, :id, :user_id, :event_id, :ticket_type_id, :attendance_id, :ticket_code, :status, :amount, :used_at, :refunded_at, :payment_reference, :transaction_id, :created_at, :updated_at
json.url event_ticket_url(event_ticket, format: :json)
