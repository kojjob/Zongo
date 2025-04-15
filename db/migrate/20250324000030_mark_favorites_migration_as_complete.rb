class MarkFavoritesMigrationAsComplete < ActiveRecord::Migration[8.0]
  def up
    # Check if the entry already exists using raw SQL
    exists = execute("SELECT 1 FROM schema_migrations WHERE version = '20250324000020'").any?
    
    unless exists
      # Add the migration version to schema_migrations to mark it as run
      execute("INSERT INTO schema_migrations (version) VALUES ('20250324000020')")
    end
  end

  def down
    # Remove the version if needed
    execute("DELETE FROM schema_migrations WHERE version = '20250324000020'")
  end
end
