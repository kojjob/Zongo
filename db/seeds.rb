# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Load seed files
puts "Loading seed data..."

# Load navigation items
if defined?(NavigationItem)
  puts "Loading navigation items..."
  load Rails.root.join('db/seeds/navigation_items.rb')
end

# Load event categories
if defined?(EventCategory)
  puts "Loading event categories..."
  load Rails.root.join('db/seeds/event_categories.rb')
end

# Load loans and credit scores
if defined?(Loan) && defined?(CreditScore)
  puts "Loading loans and credit scores..."
  load Rails.root.join('db/seeds/loans_and_credit_scores.rb')
end

# Load agriculture data
if defined?(Crop) && defined?(Region) && defined?(CropPrice) && defined?(WeatherForecast)
  puts "Loading agriculture data..."
  load Rails.root.join('db/seeds/agriculture_data.rb')
end

puts "Seed data loaded successfully!"