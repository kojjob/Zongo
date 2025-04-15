class MigrateEventFavoritesToFavorites < ActiveRecord::Migration[8.0]
  def up
    # Skip if the event_favorites table doesn't exist
    return unless ActiveRecord::Base.connection.table_exists?('event_favorites')
    
    # Skip if the favorites table doesn't exist yet
    return unless ActiveRecord::Base.connection.table_exists?('favorites')
    
    # Transfer data from event_favorites to favorites with appropriate polymorphic type
    execute <<-SQL
      INSERT INTO favorites (user_id, favoritable_type, favoritable_id, created_at, updated_at)
      SELECT user_id, 'Event', event_id, created_at, updated_at
      FROM event_favorites
      WHERE NOT EXISTS (
        SELECT 1 FROM favorites 
        WHERE favorites.user_id = event_favorites.user_id 
        AND favorites.favoritable_type = 'Event'
        AND favorites.favoritable_id = event_favorites.event_id
      )
    SQL
  end

  def down
    # This migration is not reversible since we can't determine which records came from event_favorites
    # Do nothing in the down migration
  end
end
