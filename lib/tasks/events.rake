namespace :events do
  desc "Update view counts for all events"
  task update_view_counts: :environment do
    puts "Updating event view counts..."

    # Check which column name is used in the events table
    if Event.column_names.include?("views_count")
      view_count_column = "views_count"
    elsif Event.column_names.include?("event_views_count")
      view_count_column = "event_views_count"
    else
      puts "Error: No view count column found in the events table."
      next
    end

    # Get all events
    events = Event.all
    count = 0

    # Update each event's view count
    events.each do |event|
      view_count = EventView.where(event_id: event.id).count
      event.update_column(view_count_column, view_count)
      count += 1
      print "." if count % 10 == 0
    end

    puts "\nDone! Updated view counts for #{count} events."
  end

  desc "Generate popular events report"
  task popular_report: :environment do
    puts "Generating popular events report..."

    # Determine which column to use for sorting
    view_column = Event.column_names.include?("views_count") ? "views_count" : "event_views_count"

    # Get the top 20 most viewed events
    popular_events = Event.order("#{view_column} DESC").limit(20)

    # Print report
    puts "\nTop 20 Most Viewed Events:"
    puts "---------------------------------------------------"
    puts "ID  | Views | Attendees | Title"
    puts "---------------------------------------------------"

    popular_events.each do |event|
      view_count = event.send(view_column)
      puts "#{event.id.to_s.ljust(3)} | #{view_count.to_s.ljust(5)} | #{event.attendances.count.to_s.ljust(9)} | #{event.title[0..40]}"
    end

    puts "\nDone!"
  end
end
