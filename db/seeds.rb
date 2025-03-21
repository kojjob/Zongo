# This file contains seed data for the Zongo application
# Run with: rails db:seed
# Reset and run with: rails db:seed:replant

# Helper methods
def log(message)
  puts "=== #{message} ==="
end

# Clear existing data
# Uncomment if you want to clear existing data before seeding
# log("Clearing existing data")
# EventFavorite.destroy_all
# EventComment.destroy_all
# EventMedium.destroy_all
# EventTicket.destroy_all
# Attendance.destroy_all
# TicketType.destroy_all
# Event.destroy_all
# EventCategory.destroy_all
# Venue.destroy_all
# User.where.not(email: 'admin@example.com').destroy_all

# Create users
log("Creating users")
users = []

# Admin user
admin = User.find_or_initialize_by(email: 'admin@example.com')
if admin.new_record?
  admin.assign_attributes(
    username: 'admin',
    phone: '+233500000000',
    password: 'password',
    password_confirmation: 'password',
    status: :active
  )
  admin.skip_confirmation! if admin.respond_to?(:skip_confirmation!)
  admin.save!
end
users << admin

# Regular users
regular_users_data = [
  { username: 'john_doe', email: 'john@example.com', phone: '+233501111111' },
  { username: 'jane_smith', email: 'jane@example.com', phone: '+233502222222' },
  { username: 'mike_johnson', email: 'mike@example.com', phone: '+233503333333' },
  { username: 'sarah_williams', email: 'sarah@example.com', phone: '+233504444444' },
  { username: 'david_brown', email: 'david@example.com', phone: '+233505555555' }
]

regular_users_data.each do |user_data|
  user = User.find_or_initialize_by(email: user_data[:email])
  if user.new_record?
    user.assign_attributes(
      username: user_data[:username],
      phone: user_data[:phone],
      password: 'password',
      password_confirmation: 'password',
      status: :active
    )
    user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
    user.save!
  end
  users << user
end

# Create event categories
log("Creating event categories")
categories = []

category_data = [
  { name: 'Concerts', description: 'Live music performances', icon: 'music' },
  { name: 'Conferences', description: 'Business and technology conferences', icon: 'users' },
  { name: 'Workshops', description: 'Educational and hands-on sessions', icon: 'briefcase' },
  { name: 'Sports', description: 'Sports events and competitions', icon: 'flag' },
  { name: 'Food & Drink', description: 'Food festivals and tasting events', icon: 'utensils' },
  { name: 'Arts & Theatre', description: 'Art exhibitions and theatre performances', icon: 'palette' }
]

category_data.each do |cat_data|
  category = EventCategory.find_or_initialize_by(name: cat_data[:name])
  if category.new_record?
    category.assign_attributes(
      description: cat_data[:description],
      icon: cat_data[:icon]
    )
    category.save!
  end
  categories << category
end

# Create subcategories
log("Creating subcategories")
subcategories_data = [
  { parent: 'Concerts', name: 'Rock', description: 'Rock music concerts', icon: 'guitar' },
  { parent: 'Concerts', name: 'Jazz', description: 'Jazz music performances', icon: 'saxophone' },
  { parent: 'Conferences', name: 'Technology', description: 'Tech conferences', icon: 'laptop' },
  { parent: 'Conferences', name: 'Business', description: 'Business conferences', icon: 'chart-line' },
  { parent: 'Workshops', name: 'Coding', description: 'Programming workshops', icon: 'code' },
  { parent: 'Workshops', name: 'Design', description: 'Design workshops', icon: 'pencil' },
  { parent: 'Sports', name: 'Football', description: 'Football matches', icon: 'futbol' },
  { parent: 'Sports', name: 'Basketball', description: 'Basketball games', icon: 'basketball' }
]

subcategories_data.each do |subcat_data|
  parent = EventCategory.find_by(name: subcat_data[:parent])
  next unless parent

  subcategory = EventCategory.find_or_initialize_by(name: subcat_data[:name], parent_category: parent)
  if subcategory.new_record?
    subcategory.assign_attributes(
      description: subcat_data[:description],
      icon: subcat_data[:icon]
    )
    subcategory.save!
  end
  categories << subcategory
end

# Create venues
log("Creating venues")
venues = []

venue_data = [
  {
    name: 'Accra International Conference Centre',
    description: 'A premier conference venue in Accra',
    address: 'Castle Rd',
    city: 'Accra',
    region: 'Greater Accra',
    postal_code: '233',
    country: 'Ghana',
    latitude: 5.559364,
    longitude: -0.178359,
    capacity: 1500,
    facilities: {
      parking: true,
      wifi: true,
      accessibility: true,
      air_conditioning: true,
      catering: true
    }
  },
  {
    name: 'National Theatre of Ghana',
    description: 'Home to the national dance company, drama company, and symphony orchestra',
    address: 'South Liberation Rd',
    city: 'Accra',
    region: 'Greater Accra',
    postal_code: '233',
    country: 'Ghana',
    latitude: 5.550901,
    longitude: -0.199655,
    capacity: 1500,
    facilities: {
      parking: true,
      wifi: true,
      accessibility: true,
      air_conditioning: true,
      stage_equipment: true
    }
  },
  {
    name: 'Labadi Beach Hotel',
    description: 'Luxury hotel with event facilities',
    address: 'No. 1 La Bypass',
    city: 'Accra',
    region: 'Greater Accra',
    postal_code: '233',
    country: 'Ghana',
    latitude: 5.564188,
    longitude: -0.150164,
    capacity: 500,
    facilities: {
      parking: true,
      wifi: true,
      accommodation: true,
      catering: true,
      pool: true
    }
  },
  {
    name: 'Kumasi Cultural Centre',
    description: 'Cultural venue for events in Kumasi',
    address: 'Premper III St',
    city: 'Kumasi',
    region: 'Ashanti',
    postal_code: '233',
    country: 'Ghana',
    latitude: 6.694397,
    longitude: -1.623462,
    capacity: 800,
    facilities: {
      parking: true,
      cultural_exhibits: true,
      outdoor_space: true
    }
  },
  {
    name: 'Cape Coast Castle',
    description: 'Historic venue for special events',
    address: 'Cape Coast Castle Rd',
    city: 'Cape Coast',
    region: 'Central',
    postal_code: '233',
    country: 'Ghana',
    latitude: 5.106031,
    longitude: -1.244072,
    capacity: 300,
    facilities: {
      historic_site: true,
      outdoor_space: true,
      guided_tours: true
    }
  }
]

venue_data.each do |ven_data|
  venue = Venue.find_or_initialize_by(name: ven_data[:name])
  if venue.new_record?
    venue.assign_attributes(
      description: ven_data[:description],
      address: ven_data[:address],
      city: ven_data[:city],
      region: ven_data[:region],
      postal_code: ven_data[:postal_code],
      country: ven_data[:country],
      latitude: ven_data[:latitude],
      longitude: ven_data[:longitude],
      capacity: ven_data[:capacity],
      facilities: ven_data[:facilities],
      user: users.sample
    )
    venue.save!
  end
  venues << venue
end

# Create events
log("Creating events")
events = []

# Current date for reference
now = Time.current
today = Date.current

# Helper method to generate random date
def random_date(from, to)
  Time.at(from + rand * (to.to_f - from.to_f))
end

# Helper method to generate random future date
def random_future_date(days_from_now_min, days_from_now_max)
  from = Time.current + days_from_now_min.days
  to = Time.current + days_from_now_max.days
  random_date(from, to)
end

# Helper method to generate random past date
def random_past_date(days_ago_min, days_ago_max)
  from = Time.current - days_ago_max.days
  to = Time.current - days_ago_min.days
  random_date(from, to)
end

event_data = [
  {
    title: 'Annual Tech Conference 2025',
    description: 'Join us for the annual tech conference where industry leaders share insights about the latest trends and technologies. This year\'s focus will be on artificial intelligence, blockchain, and sustainable tech solutions. The event includes keynote speeches, panel discussions, workshops, and networking opportunities.',
    short_description: 'The premier tech event of the year featuring industry leaders and innovators.',
    start_time: random_future_date(30, 60).change(hour: 9),
    duration_hours: 8,
    capacity: 800,
    is_featured: true,
    category: 'Technology',
    venue: 'Accra International Conference Centre',
    status: :published
  },
  {
    title: 'Ghana Music Awards',
    description: 'The annual Ghana Music Awards celebrates the best in Ghanaian music across all genres. The event features live performances from nominated artists, awards presentations, and special tributes to legends of Ghanaian music. Join us for a night of celebration, entertainment, and recognition of musical excellence.',
    short_description: 'Ghana\'s biggest night of music and entertainment.',
    start_time: random_future_date(45, 75).change(hour: 19),
    duration_hours: 5,
    capacity: 1200,
    is_featured: true,
    category: 'Concerts',
    venue: 'National Theatre of Ghana',
    status: :published
  },
  {
    title: 'Business Leadership Workshop',
    description: 'This intensive workshop is designed for business leaders and entrepreneurs looking to enhance their leadership skills. Topics covered include strategic planning, team management, crisis handling, and sustainable business practices. The workshop will be facilitated by experienced business coaches and includes practical exercises and case studies.',
    short_description: 'Enhance your leadership skills with this intensive workshop.',
    start_time: random_future_date(15, 30).change(hour: 10),
    duration_hours: 6,
    capacity: 100,
    is_featured: false,
    category: 'Business',
    venue: 'Labadi Beach Hotel',
    status: :published
  },
  {
    title: 'Accra Food Festival',
    description: 'The Accra Food Festival is a celebration of Ghanaian and international cuisine. Visitors can enjoy food tastings, cooking demonstrations, chef competitions, and cultural performances. The festival showcases the rich culinary heritage of Ghana and introduces visitors to diverse international cuisines. Don\'t miss this gastronomic adventure!',
    short_description: 'A celebration of Ghanaian and international cuisine.',
    start_time: random_future_date(20, 40).change(hour: 11),
    duration_hours: 10,
    capacity: 5000,
    is_featured: true,
    category: 'Food & Drink',
    venue: 'Accra International Conference Centre',
    status: :published
  },
  {
    title: 'Kumasi Cultural Festival',
    description: 'The Kumasi Cultural Festival showcases the rich cultural heritage of the Ashanti region. The event features traditional dance performances, drumming, storytelling, arts and crafts exhibitions, and cultural displays. Visitors will have the opportunity to learn about Ashanti history, traditions, and customs through immersive experiences and interactions with cultural ambassadors.',
    short_description: 'Celebrating the rich cultural heritage of the Ashanti region.',
    start_time: random_future_date(60, 90).change(hour: 10),
    duration_hours: 48,
    capacity: 2000,
    is_featured: true,
    category: 'Arts & Theatre',
    venue: 'Kumasi Cultural Centre',
    status: :published
  },
  {
    title: 'Web Development Bootcamp',
    description: 'This intensive bootcamp is designed for aspiring web developers. Over the course of three days, participants will learn the fundamentals of HTML, CSS, JavaScript, and responsive design. The bootcamp includes hands-on projects, code reviews, and mentoring sessions with experienced developers. By the end, participants will have built their own responsive website.',
    short_description: 'Learn web development fundamentals in this hands-on bootcamp.',
    start_time: random_future_date(10, 25).change(hour: 9),
    duration_hours: 24,
    capacity: 50,
    is_featured: false,
    category: 'Coding',
    venue: 'Accra International Conference Centre',
    status: :published
  },
  {
    title: 'Ghana vs. Nigeria Friendly Match',
    description: 'Don\'t miss this exciting friendly football match between Ghana and Nigeria. The two teams have a long-standing rivalry, and this match promises to be an entertaining showcase of African football talent. Come support the Black Stars as they face the Super Eagles in this highly anticipated match.',
    short_description: 'Exciting friendly match between Ghana and Nigeria.',
    start_time: random_future_date(30, 50).change(hour: 15),
    duration_hours: 2,
    capacity: 40000,
    is_featured: true,
    category: 'Football',
    venue: 'National Theatre of Ghana', # In reality would be a stadium
    status: :published
  },
  {
    title: 'Jazz Night at Cape Coast',
    description: 'Enjoy an evening of smooth jazz at the historic Cape Coast Castle. This unique event combines great music with a historic setting, creating an unforgettable experience. The lineup includes both local and international jazz musicians. Food and drinks will be available for purchase. Come early to enjoy a guided tour of the castle before the music begins.',
    short_description: 'An evening of smooth jazz in a historic setting.',
    start_time: random_future_date(20, 45).change(hour: 18),
    duration_hours: 4,
    capacity: 300,
    is_featured: false,
    category: 'Jazz',
    venue: 'Cape Coast Castle',
    status: :published
  },
  {
    title: 'UX Design Masterclass',
    description: 'This masterclass is for designers who want to enhance their user experience design skills. Led by industry experts, the workshop covers user research, wireframing, prototyping, and usability testing. Participants will work on real-world projects and receive feedback from experienced UX designers. This is an intermediate level workshop, so basic design knowledge is required.',
    short_description: 'Enhance your UX design skills with industry experts.',
    start_time: random_future_date(15, 35).change(hour: 10),
    duration_hours: 6,
    capacity: 40,
    is_featured: false,
    category: 'Design',
    venue: 'Labadi Beach Hotel',
    status: :published
  },
  {
    title: 'Startup Pitch Competition',
    description: 'This pitch competition gives Ghanaian startups the opportunity to present their ideas to investors and win funding. Ten pre-selected startups will pitch their business ideas to a panel of judges, including venture capitalists and successful entrepreneurs. The event also includes networking sessions and talks by business leaders. Don\'t miss this chance to see the future of Ghanaian innovation!',
    short_description: 'Ghana\'s startups compete for investor funding and recognition.',
    start_time: random_future_date(25, 55).change(hour: 13),
    duration_hours: 5,
    capacity: 200,
    is_featured: true,
    category: 'Business',
    venue: 'Accra International Conference Centre',
    status: :published
  },
  # Past events
  {
    title: 'Past Tech Workshop',
    description: 'This was a workshop focused on emerging technologies and their applications in various industries.',
    short_description: 'A workshop on emerging technologies.',
    start_time: random_past_date(10, 30).change(hour: 10),
    duration_hours: 6,
    capacity: 100,
    is_featured: false,
    category: 'Technology',
    venue: 'Accra International Conference Centre',
    status: :completed
  },
  {
    title: 'Ghana Independence Concert',
    description: 'This concert celebrated Ghana\'s independence with performances by top Ghanaian artists.',
    short_description: 'Celebrating Ghana\'s independence with music.',
    start_time: random_past_date(15, 45).change(hour: 18),
    duration_hours: 5,
    capacity: 1000,
    is_featured: false,
    category: 'Concerts',
    venue: 'National Theatre of Ghana',
    status: :completed
  }
]

event_data.each do |e_data|
  # Find category
  category = if e_data[:category].present?
               EventCategory.find_by(name: e_data[:category]) || categories.sample
  else
               categories.sample
  end

  # Find venue
  venue = if e_data[:venue].present?
            Venue.find_by(name: e_data[:venue]) || venues.sample
  else
            venues.sample
  end

  # Calculate end time
  start_time = e_data[:start_time]
  end_time = start_time + e_data[:duration_hours].hours

  # Create event
  event = Event.find_or_initialize_by(title: e_data[:title])
  if event.new_record?
    event.assign_attributes(
      description: e_data[:description],
      short_description: e_data[:short_description],
      start_time: start_time,
      end_time: end_time,
      capacity: e_data[:capacity],
      status: e_data[:status],
      is_featured: e_data[:is_featured],
      is_private: false,
      slug: e_data[:title].parameterize,
      organizer: users.sample,
      event_category: category,
      venue: venue,
      recurrence_type: 0, # One-time event
      views_count: rand(50..500),
      favorites_count: rand(10..100)
    )
    event.save!
  end
  events << event
end

# Create ticket types for each event
log("Creating ticket types")
ticket_types = []

events.each do |event|
  # Skip if it's a past event or already has ticket types
  next if event.ended? || event.ticket_types.exists?

  # VIP Ticket
  vip_price = rand(200..500)
  vip_ticket = TicketType.create!(
    event: event,
    name: 'VIP',
    description: 'Premium seating with exclusive benefits',
    price: vip_price,
    quantity: (event.capacity * 0.2).to_i, # 20% of capacity
    sales_start_time: event.start_time - 30.days,
    sales_end_time: event.start_time - 1.day,
    max_per_user: 4,
    transferable: true
  )
  ticket_types << vip_ticket

  # Standard Ticket
  standard_price = rand(50..150)
  standard_ticket = TicketType.create!(
    event: event,
    name: 'Standard',
    description: 'Regular admission',
    price: standard_price,
    quantity: (event.capacity * 0.6).to_i, # 60% of capacity
    sales_start_time: event.start_time - 30.days,
    sales_end_time: event.start_time - 1.day,
    max_per_user: 6,
    transferable: true
  )
  ticket_types << standard_ticket

  # Early Bird Ticket (if event is more than 14 days away)
  if !event.ended? && event.start_time > Time.current + 14.days
    early_bird_price = standard_price * 0.7 # 30% discount
    early_bird_ticket = TicketType.create!(
      event: event,
      name: 'Early Bird',
      description: 'Discounted early admission, limited availability',
      price: early_bird_price,
      quantity: (event.capacity * 0.2).to_i, # 20% of capacity
      sales_start_time: event.start_time - 30.days,
      sales_end_time: event.start_time - 14.days,
      max_per_user: 2,
      transferable: false
    )
    ticket_types << early_bird_ticket
  end
end

# Create attendances and tickets for some users to some events
log("Creating attendances and tickets")

attendances = []
event_tickets = []

# Only create for future events
future_events = events.select { |e| e.start_time > Time.current }

future_events.each do |event|
  # Decide how many users will attend (10-50% of capacity)
  attendance_count = rand((event.capacity * 0.1)..(event.capacity * 0.5)).to_i

  # Get the ticket types for this event
  event_ticket_types = event.ticket_types.to_a
  next if event_ticket_types.empty?

  # Get all available users who haven't registered for this event yet
  available_users = users.reject do |user|
    Attendance.exists?(user: user, event: event)
  end

  # Randomly select users to attend (but no more than we have available)
  attending_users = available_users.sample([ attendance_count, available_users.size ].min)

  attending_users.each do |user|
    # Create attendance record
    attendance = Attendance.create!(
      user: user,
      event: event,
      status: [ :registered, :confirmed, :checked_in ].sample,
      additional_info: { notes: "Automatically created via seed" }
    )
    attendances << attendance

    # Decide how many tickets this user buys (1-4)
    ticket_count = rand(1..4)

    ticket_count.times do
      # Randomly select a ticket type
      ticket_type = event_ticket_types.sample

      # Create a ticket
      ticket = EventTicket.create!(
        user: user,
        event: event,
        ticket_type: ticket_type,
        attendance: attendance,
        ticket_code: "SEED-#{SecureRandom.hex(6).upcase}",
        status: [ :pending, :confirmed ].sample,
        amount: ticket_type.price
      )
      event_tickets << ticket
    end
  end
end

# Create event comments
log("Creating event comments")
comments = []

events.each do |event|
  # Skip if it's a future event (no comments yet)
  next if event.start_time > Time.current

  # Decide how many comments (0-20)
  comment_count = rand(0..20)

  comment_count.times do
    user = users.sample
    content = [
      "Great event! Looking forward to it.",
      "Will there be parking available?",
      "I've been to similar events by this organizer before, and they're always excellent.",
      "What's the dress code for this event?",
      "Can't wait! This is going to be amazing.",
      "Are there any discounts for students?",
      "The venue is excellent, I've been there before.",
      "Is this suitable for children?",
      "Will the event be recorded?",
      "Last year's event was fantastic, hoping this will be even better!"
    ].sample

    comment = EventComment.create!(
      event: event,
      user: user,
      content: content,
      likes_count: rand(0..15),
      is_hidden: [ true, false, false, false, false ].sample # 20% chance of being hidden
    )
    comments << comment

    # Maybe add replies (0-3)
    reply_count = rand(0..3)

    reply_count.times do
      reply_user = users.sample
      reply_content = [
        "I agree!",
        "Thanks for the information.",
        "Good point, I was wondering the same thing.",
        "The organizer usually responds quickly to questions.",
        "Yes, I think so.",
        "No, I don't think that's the case.",
        "Great question, I'd like to know too."
      ].sample

      reply = EventComment.create!(
        event: event,
        user: reply_user,
        parent_comment: comment,
        content: reply_content,
        likes_count: rand(0..5),
        is_hidden: [ true, false, false, false, false ].sample # 20% chance of being hidden
      )
      comments << reply
    end
  end
end

# Create event favorites
log("Creating event favorites")
favorites = []

events.each do |event|
  # Decide how many users favorite this event (0-50)
  favorite_count = rand(0..50)

  # Randomly select users to favorite (but no more than we have)
  favoriting_users = users.sample([ favorite_count, users.size ].min)

  favoriting_users.each do |user|
    favorite = EventFavorite.find_or_initialize_by(event: event, user: user)
    if favorite.new_record?
      favorite.save!
      favorites << favorite
    end
  end
end

# Create event media
log("Creating event media")
event_media = []

# Helper methods for creating media attachments
def create_dummy_image(filename = "image.jpg")
  file = Tempfile.new([ File.basename(filename, ".*"), File.extname(filename) ])
  file.binmode
  # Create a simple colored rectangle as a valid JPEG
  require 'mini_magick'
  image = MiniMagick::Image.create(file.path, false) do |f|
    f.background "##{SecureRandom.hex(3)}"
    f.size "600x400"
  end
  file.close
  file
end

def create_dummy_audio(filename = "audio.mp3")
  file = Tempfile.new([ File.basename(filename, ".*"), File.extname(filename) ])
  file.binmode
  # Simply create a file with MP3 header bytes
  file.write("ID3\x03\x00\x00\x00\x00\x00\x1F")
  file.close
  file
end

def create_dummy_video(filename = "video.mp4")
  file = Tempfile.new([ File.basename(filename, ".*"), File.extname(filename) ])
  file.binmode
  # Add simple MP4 file header bytes
  file.write("\x00\x00\x00\x18ftypmp42\x00\x00\x00\x00mp42isom\x00\x00\x00\x01mdat")
  file.close
  file
end

def create_dummy_document(filename = "document.pdf")
  file = Tempfile.new([ File.basename(filename, ".*"), File.extname(filename) ])
  file.binmode
  # Add PDF header
  file.write("%PDF-1.5\n%âãÏÓ\n")
  file.close
  file
end

# Create media for selected events
events.each do |event|
  # Randomly decide if this event gets media (80% chance)
  next unless rand < 0.8

  # Add 1-5 media items for this event
  media_count = rand(1..5)

  media_count.times do |i|
    # Decide media type (70% image, 15% video, 10% audio, 5% document)
    media_type_rand = rand
    media_type = if media_type_rand < 0.7
                   :image
    elsif media_type_rand < 0.85
                   :video
    elsif media_type_rand < 0.95
                   :audio
    else
                   :document
    end

    # Create title and description
    title = case media_type
    when :image
              [ "Event Photo", "Venue Setup", "Speaker", "Audience", "Stage" ].sample
    when :video
              [ "Event Promo", "Speaker Interview", "Highlight Reel", "Teaser" ].sample
    when :audio
              [ "Speaker Introduction", "Event Theme Song", "Audio Announcement" ].sample
    when :document
              [ "Event Schedule", "Speaker Bio", "Registration Form", "Sponsorship Packet" ].sample
    end

    title = "#{title} #{i+1}" if i > 0
    description = "#{media_type.to_s.capitalize} for #{event.title}"

    # Create the media record
    medium = EventMedium.new(
      event: event,
      user: users.sample,
      media_type: media_type,
      title: title,
      description: description,
      is_featured: i == 0, # First media item is featured
      display_order: i
    )

    # Attach the appropriate dummy file
    case media_type
    when :image
      file = create_dummy_image("#{event.slug}-image-#{i}.jpg")
      medium.file.attach(
        io: File.open(file.path),
        filename: "#{event.slug}-image-#{i}.jpg",
        content_type: 'image/jpeg'
      )
    when :video
      file = create_dummy_video("#{event.slug}-video-#{i}.mp4")
      medium.file.attach(
        io: File.open(file.path),
        filename: "#{event.slug}-video-#{i}.mp4",
        content_type: 'video/mp4'
      )
    when :audio
      file = create_dummy_audio("#{event.slug}-audio-#{i}.mp3")
      medium.file.attach(
        io: File.open(file.path),
        filename: "#{event.slug}-audio-#{i}.mp3",
        content_type: 'audio/mpeg'
      )
    when :document
      file = create_dummy_document("#{event.slug}-document-#{i}.pdf")
      medium.file.attach(
        io: File.open(file.path),
        filename: "#{event.slug}-document-#{i}.pdf",
        content_type: 'application/pdf'
      )
    end

    # Save the media
    medium.save!
    event_media << medium
  end
end

# Success message
log("Seed data created successfully!")
log("Created #{users.size} users")
log("Created #{categories.size} event categories")
log("Created #{venues.size} venues")
log("Created #{events.size} events")
log("Created #{ticket_types.size} ticket types")
log("Created #{attendances.size} attendances")
log("Created #{event_tickets.size} event tickets")
log("Created #{comments.size} comments")
log("Created #{favorites.size} favorites")
log("Created #{event_media.size} event media items")
