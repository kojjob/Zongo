# Ensure categories exist
puts "Creating categories..."
[
  { name: "Music & Art", icon: "music", color_code: "#8B5CF6" },
  { name: "Sports", icon: "activity", color_code: "#3B82F6" },
  { name: "Food & Drink", icon: "utensils", color_code: "#F59E0B" },
  { name: "Technology", icon: "code", color_code: "#10B981" },
  { name: "Business", icon: "briefcase", color_code: "#6B7280" },
  { name: "Education", icon: "book-open", color_code: "#EF4444" },
  { name: "Community", icon: "users", color_code: "#EC4899" },
  { name: "Health & Wellness", icon: "heart", color_code: "#14B8A6" }
].each do |category_data|
  Category.find_or_create_by!(name: category_data[:name]) do |category|
    category.icon = category_data[:icon]
    category.color_code = category_data[:color_code]
  end
end

# Create venues if they don't exist
puts "Creating venues..."
venues = [
  { name: "National Theater", address: "South Liberia Road, Accra, Ghana", capacity: 1500 },
  { name: "Accra Sports Stadium", address: "Starlets 91 Rd, Accra, Ghana", capacity: 40000 },
  { name: "Trade Fair Centre", address: "La Palm, Accra, Ghana", capacity: 5000 },
  { name: "Coconut Grove Regency Hotel", address: "Ridge, Accra, Ghana", capacity: 500 },
  { name: "Alliance Française Accra", address: "Liberation Link, Accra, Ghana", capacity: 300 }
]

venues.each do |venue_attrs|
  Venue.find_or_create_by!(name: venue_attrs[:name]) do |venue|
    venue.address = venue_attrs[:address]
    venue.capacity = venue_attrs[:capacity]
  end
end

# Find a user to be the organizer
puts "Finding or creating user..."
user = User.first_or_create!(
  email: "admin@example.com", 
  password: "password123", 
  name: "Admin User"
)

# Create some sample events
puts "Creating events..."
events_data = [
  {
    title: "Ghana Independence Day Celebration",
    description: "Join us as we celebrate Ghana's independence with music, dance, and food.",
    short_description: "Celebrate Ghana's independence with cultural performances.",
    start_time: 2.days.from_now.change(hour: 10),
    end_time: 2.days.from_now.change(hour: 22),
    venue: Venue.find_by(name: "National Theater"),
    category: Category.find_by(name: "Community"),
    price: 0,
    capacity: 1000,
    is_featured: true
  },
  {
    title: "Tech Meetup Accra",
    description: "A meetup for tech enthusiasts to network and learn from each other.",
    short_description: "Network with fellow tech enthusiasts in Accra.",
    start_time: 5.days.from_now.change(hour: 18),
    end_time: 5.days.from_now.change(hour: 21),
    venue: Venue.find_by(name: "Alliance Française Accra"),
    category: Category.find_by(name: "Technology"),
    price: 0,
    capacity: 200
  },
  {
    title: "Ghana Music Awards",
    description: "Annual music awards celebrating Ghanaian musicians and their contributions.",
    short_description: "Celebrate the best in Ghanaian music.",
    start_time: 10.days.from_now.change(hour: 19),
    end_time: 10.days.from_now.change(hour: 23),
    venue: Venue.find_by(name: "National Theater"),
    category: Category.find_by(name: "Music & Art"),
    price: 150,
    capacity: 1500
  },
  {
    title: "Accra International Marathon",
    description: "Annual marathon through the streets of Accra.",
    short_description: "Run through the beautiful streets of Accra.",
    start_time: 15.days.from_now.change(hour: 6),
    end_time: 15.days.from_now.change(hour: 12),
    venue: Venue.find_by(name: "Accra Sports Stadium"),
    category: Category.find_by(name: "Sports"),
    price: 50,
    capacity: 5000
  },
  {
    title: "Ghana Food Festival",
    description: "Celebration of Ghanaian cuisine with food stalls and cooking demonstrations.",
    short_description: "Taste the best of Ghanaian cuisine.",
    start_time: 7.days.from_now.change(hour: 10),
    end_time: 7.days.from_now.change(hour: 18),
    venue: Venue.find_by(name: "Trade Fair Centre"),
    category: Category.find_by(name: "Food & Drink"),
    price: 20,
    capacity: 3000
  }
]

events_data.each do |event_data|
  event = Event.find_or_create_by!(title: event_data[:title]) do |e|
    e.description = event_data[:description]
    e.short_description = event_data[:short_description]
    e.start_time = event_data[:start_time]
    e.end_time = event_data[:end_time]
    e.venue = event_data[:venue]
    e.category = event_data[:category]
    e.price = event_data[:price]
    e.capacity = event_data[:capacity]
    e.is_featured = event_data[:is_featured] || false
    e.organizer = user
  end
  
  # Create some placeholder event media
  unless event.event_media.exists?
    event.event_media.create!(
      url: "/assets/events/#{['event1', 'event2', 'event3', 'festival', 'concert'].sample}.jpg",
      media_type: "image"
    )
  end
  
  # Create some attendances if needed
  if event.attendances.count < 5
    5.times do
      # Create a random user to attend the event if needed
      attendee = User.all.sample || User.create!(
        email: "user#{rand(1000)}@example.com",
        password: "password123",
        name: "Attendee #{rand(1000)}"
      )
      
      # Make them attend if they're not already attending
      unless event.attendances.exists?(user_id: attendee.id)
        event.attendances.create!(user: attendee)
      end
    end
  end
end

puts "Seed data created successfully!"