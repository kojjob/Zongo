json.extract! ticket_type, :id, :event_id, :name, :description, :price, :quantity, :sales_start_time, :sales_end_time, :sold_count, :max_per_user, :transferable, :created_at, :updated_at
json.url ticket_type_url(ticket_type, format: :json)
