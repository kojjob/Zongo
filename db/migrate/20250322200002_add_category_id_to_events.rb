class AddCategoryIdToEvents < ActiveRecord::Migration[8.0]
  def up
    # Add category_id column to events table
    add_reference :events, :category, foreign_key: true, index: true

    # If there's data in event_category_id, we need to map it to the new category_id
    # This is a simplified example - in a real migration you'd want to handle this carefully
    if column_exists?(:events, :event_category_id) && ActiveRecord::Base.connection.table_exists?('event_categories') && ActiveRecord::Base.connection.table_exists?('categories')
      # For each event_category, find or create a matching category
      execute <<-SQL
        UPDATE events
        SET category_id = (
          SELECT id FROM categories
          WHERE name = (
            SELECT name FROM event_categories#{' '}
            WHERE event_categories.id = events.event_category_id
          )
          LIMIT 1
        )
        WHERE event_category_id IS NOT NULL
      SQL
    end
  end

  def down
    remove_reference :events, :category
  end
end
