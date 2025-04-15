namespace :database do
  desc "Mark specific migrations as already run"
  task mark_migrations_complete: :environment do
    # List of migrations to mark as complete
    migrations_to_mark = ['20250324000020']
    
    puts "Marking migrations as complete..."
    
    # Get a connection to the database
    conn = ActiveRecord::Base.connection
    
    migrations_to_mark.each do |version|
      # Check if the migration is already marked as run
      if conn.select_value("SELECT version FROM schema_migrations WHERE version = '#{version}'")
        puts "Migration #{version} is already marked as complete."
      else
        # Mark it as complete
        conn.execute("INSERT INTO schema_migrations (version) VALUES ('#{version}')")
        puts "Marked migration #{version} as complete."
      end
    end
    
    puts "Done!"
  end
end
