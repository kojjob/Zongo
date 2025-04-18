class EventTag < ApplicationRecord
  # Check if the tables exist before defining associations
  begin
    if ActiveRecord::Base.connection.table_exists?("events")
      belongs_to :event
    end

    if ActiveRecord::Base.connection.table_exists?("tags")
      belongs_to :tag, counter_cache: :events_count
    end
  rescue ActiveRecord::StatementInvalid => e
    # Tables don't exist yet, associations will be set up when migrations are run
  end

  validates :event_id, uniqueness: { scope: :tag_id }

  # Class method to check if related tables exist
  def self.tables_exist?
    ActiveRecord::Base.connection.table_exists?("event_tags") &&
    ActiveRecord::Base.connection.table_exists?("events") &&
    ActiveRecord::Base.connection.table_exists?("tags")
  rescue ActiveRecord::StatementInvalid => e
    false
  end
end
