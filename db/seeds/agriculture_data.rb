# Create regions
puts "Creating regions..."
regions = [
  { name: "Greater Accra", code: "GA", description: "The capital region of Ghana", latitude: 5.6037, longitude: -0.1870 },
  { name: "Ashanti", code: "AS", description: "The cultural heartland of Ghana", latitude: 6.7000, longitude: -1.6333 },
  { name: "Northern", code: "NR", description: "The largest region by land area", latitude: 9.5000, longitude: -0.9833 },
  { name: "Western", code: "WR", description: "The region with abundant natural resources", latitude: 4.8833, longitude: -1.7500 },
  { name: "Eastern", code: "ER", description: "Known for its beautiful landscapes", latitude: 6.1000, longitude: -0.2500 },
  { name: "Central", code: "CR", description: "Rich in history and culture", latitude: 5.1000, longitude: -1.2500 },
  { name: "Volta", code: "VR", description: "Home to Lake Volta, the largest artificial lake", latitude: 6.5833, longitude: 0.4667 },
  { name: "Upper East", code: "UE", description: "Known for its unique architecture", latitude: 10.7000, longitude: -0.8500 },
  { name: "Upper West", code: "UW", description: "The northwestern region of Ghana", latitude: 10.8000, longitude: -2.5000 },
  { name: "Bono", code: "BR", description: "Known for its agricultural productivity", latitude: 7.7500, longitude: -2.5000 }
]

regions.each do |region_data|
  Region.find_or_create_by!(name: region_data[:name]) do |region|
    region.code = region_data[:code]
    region.description = region_data[:description]
    region.latitude = region_data[:latitude]
    region.longitude = region_data[:longitude]
  end
end

# Create crops
puts "Creating crops..."
crops = [
  {
    name: "Maize",
    description: "Maize is one of the most important cereal crops in Ghana. It is grown in all agro-ecological zones of the country and is a staple food for many Ghanaians.",
    scientific_name: "Zea mays",
    growing_season: "Major: April-July, Minor: September-November",
    season_start: 4,
    season_end: 11,
    growing_time: 90,
    category: :grain,
    popularity: 95,
    featured: true
  },
  {
    name: "Rice",
    description: "Rice is a major cereal crop in Ghana, grown mainly in the northern, upper east, and volta regions. It's becoming increasingly important in the Ghanaian diet.",
    scientific_name: "Oryza sativa",
    growing_season: "May-November",
    season_start: 5,
    season_end: 11,
    growing_time: 120,
    category: :grain,
    popularity: 90,
    featured: true
  },
  {
    name: "Cassava",
    description: "Cassava is a root crop widely cultivated in Ghana. It is a major source of carbohydrates and is processed into various food products.",
    scientific_name: "Manihot esculenta",
    growing_season: "Year-round, best planted at onset of rains",
    season_start: 3,
    season_end: 10,
    growing_time: 270,
    category: :root,
    popularity: 85,
    featured: true
  },
  {
    name: "Yam",
    description: "Yam is an important staple food in Ghana, particularly in the forest and transitional zones. It is a major source of income for many farmers.",
    scientific_name: "Dioscorea spp.",
    growing_season: "December-July",
    season_start: 12,
    season_end: 7,
    growing_time: 210,
    category: :root,
    popularity: 80,
    featured: true
  },
  {
    name: "Plantain",
    description: "Plantain is a major staple food in Ghana, particularly in the forest zone. It is consumed in various forms and is an important source of income for farmers.",
    scientific_name: "Musa paradisiaca",
    growing_season: "Year-round, best planted at onset of rains",
    season_start: 3,
    season_end: 10,
    growing_time: 300,
    category: :fruit,
    popularity: 75,
    featured: true
  },
  {
    name: "Cocoa",
    description: "Cocoa is Ghana's main cash crop and a major foreign exchange earner. Ghana is the world's second-largest producer of cocoa beans.",
    scientific_name: "Theobroma cacao",
    growing_season: "Main crop: October-March, Light crop: May-August",
    season_start: 10,
    season_end: 8,
    growing_time: 1825,
    category: :cash_crop,
    popularity: 100,
    featured: true
  },
  {
    name: "Tomato",
    description: "Tomatoes are an important vegetable crop in Ghana, used in many local dishes. They are grown mainly in the dry season under irrigation.",
    scientific_name: "Solanum lycopersicum",
    growing_season: "October-April",
    season_start: 10,
    season_end: 4,
    growing_time: 90,
    category: :vegetable,
    popularity: 70,
    featured: false
  },
  {
    name: "Pepper",
    description: "Peppers, both hot and sweet varieties, are widely grown in Ghana and are essential ingredients in Ghanaian cuisine.",
    scientific_name: "Capsicum spp.",
    growing_season: "Year-round, best in dry season",
    season_start: 10,
    season_end: 4,
    growing_time: 90,
    category: :vegetable,
    popularity: 65,
    featured: false
  },
  {
    name: "Groundnut",
    description: "Groundnuts (peanuts) are an important legume crop in Ghana, providing both food and income for many farmers, especially in the northern regions.",
    scientific_name: "Arachis hypogaea",
    growing_season: "April-October",
    season_start: 4,
    season_end: 10,
    growing_time: 120,
    category: :legume,
    popularity: 60,
    featured: false
  },
  {
    name: "Cowpea",
    description: "Cowpea is a drought-resistant legume crop grown mainly in the northern regions of Ghana. It is an important source of protein in the Ghanaian diet.",
    scientific_name: "Vigna unguiculata",
    growing_season: "May-November",
    season_start: 5,
    season_end: 11,
    growing_time: 70,
    category: :legume,
    popularity: 55,
    featured: false
  },
  {
    name: "Sorghum",
    description: "Sorghum is a drought-resistant cereal crop grown mainly in the northern regions of Ghana. It is used for food, animal feed, and brewing local beer.",
    scientific_name: "Sorghum bicolor",
    growing_season: "May-October",
    season_start: 5,
    season_end: 10,
    growing_time: 120,
    category: :grain,
    popularity: 50,
    featured: false
  },
  {
    name: "Millet",
    description: "Millet is a drought-resistant cereal crop grown mainly in the northern regions of Ghana. It is an important food crop in these areas.",
    scientific_name: "Pennisetum glaucum",
    growing_season: "May-October",
    season_start: 5,
    season_end: 10,
    growing_time: 90,
    category: :grain,
    popularity: 45,
    featured: false
  }
]

crops.each do |crop_data|
  Crop.find_or_create_by!(name: crop_data[:name]) do |crop|
    crop.description = crop_data[:description]
    crop.scientific_name = crop_data[:scientific_name]
    crop.growing_season = crop_data[:growing_season]
    crop.season_start = crop_data[:season_start]
    crop.season_end = crop_data[:season_end]
    crop.growing_time = crop_data[:growing_time]
    crop.category = crop_data[:category]
    crop.popularity = crop_data[:popularity]
    crop.featured = crop_data[:featured]
  end
end

# Create crop prices
puts "Creating crop prices..."
crops = Crop.all
regions = Region.all
markets = ["Agbogbloshie Market", "Makola Market", "Techiman Market", "Tamale Market", "Kumasi Central Market"]
units = ["kg", "bag", "crate", "bunch"]

# Current date for reference
current_date = Date.today

# Generate prices for the last 90 days
(0..90).each do |days_ago|
  date = current_date - days_ago.days

  crops.each do |crop|
    # Base price for each crop
    base_price = case crop.category
                 when "grain" then rand(3.0..8.0)
                 when "root" then rand(2.0..6.0)
                 when "vegetable" then rand(5.0..15.0)
                 when "fruit" then rand(4.0..12.0)
                 when "legume" then rand(6.0..10.0)
                 when "cash_crop" then rand(20.0..40.0)
                 else rand(5.0..10.0)
                 end

    # Add some seasonal variation
    month_factor = if (crop.season_start..crop.season_end).include?(date.month)
                     rand(0.8..1.0) # In season - lower prices
                   else
                     rand(1.0..1.5) # Out of season - higher prices
                   end

    # Add some random variation over time
    time_variation = Math.sin(days_ago / 15.0) * 0.2 + 1.0

    # Calculate final price
    price = base_price * month_factor * time_variation

    # Create price records for different regions and markets
    rand(1..3).times do
      region = regions.sample
      market = markets.sample
      unit = units.sample

      # Add regional variation
      regional_factor = rand(0.9..1.1)

      CropPrice.create!(
        crop: crop,
        region: region,
        price: (price * regional_factor).round(2),
        date: date,
        unit: unit,
        market: market,
        notes: "Regular market price"
      )
    end
  end
end

# Create weather forecasts
puts "Creating weather forecasts..."
regions = Region.all
weather_conditions = WeatherForecast.weather_conditions.keys

# Generate forecasts for the next 7 days
(0..7).each do |days_from_now|
  date = current_date + days_from_now.days

  regions.each do |region|
    # Base temperatures based on region's latitude (northern regions hotter and drier)
    is_northern = region.latitude > 8.0

    base_high = is_northern ? rand(30..36) : rand(26..32)
    base_low = is_northern ? rand(22..26) : rand(20..24)

    # Seasonal adjustments
    month = date.month
    if [12, 1, 2].include?(month) # Harmattan season
      base_high += rand(2..4)
      base_low -= rand(2..4)
      precipitation_chance = rand(0..20)
      precipitation_amount = rand(0..5)
      condition = is_northern ? 'sunny' : ['sunny', 'partly_cloudy'].sample
    elsif [3, 4, 5].include?(month) # Major rainy season
      precipitation_chance = rand(40..90)
      precipitation_amount = rand(5..25)
      condition = ['partly_cloudy', 'cloudy', 'rainy', 'stormy'].sample
    elsif [6, 7].include?(month) # Minor dry season
      precipitation_chance = rand(20..50)
      precipitation_amount = rand(2..10)
      condition = ['partly_cloudy', 'cloudy'].sample
    else # Minor rainy season
      precipitation_chance = rand(30..70)
      precipitation_amount = rand(3..15)
      condition = ['partly_cloudy', 'cloudy', 'rainy'].sample
    end

    # Random daily variations
    temp_variation = rand(-2.0..2.0)

    WeatherForecast.create!(
      region: region,
      forecast_date: date,
      temperature_high: (base_high + temp_variation).round(1),
      temperature_low: (base_low + temp_variation).round(1),
      precipitation_chance: precipitation_chance,
      precipitation_amount: precipitation_amount,
      weather_condition: condition,
      wind_speed: rand(5..20),
      wind_direction: ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'].sample,
      humidity: rand(50..95),
      notes: "Forecast for #{region.name} region"
    )
  end
end

# Create sample crop listings
puts "Creating sample crop listings..."
users = User.all.limit(10)
crops = Crop.all
regions = Region.all
listing_types = CropListing.listing_types.keys
statuses = [:active, :active, :active, :pending, :sold]
units = ["kg", "bag", "ton", "crate", "bunch"]

if users.present?
  50.times do
    user = users.sample
    crop = crops.sample
    region = regions.sample
    listing_type = listing_types.sample
    status = statuses.sample
    unit = units.sample

    # Base price based on crop category and listing type
    base_price = case crop.category
                 when "grain" then rand(3.0..8.0)
                 when "root" then rand(2.0..6.0)
                 when "vegetable" then rand(5.0..15.0)
                 when "fruit" then rand(4.0..12.0)
                 when "legume" then rand(6.0..10.0)
                 when "cash_crop" then rand(20.0..40.0)
                 else rand(5.0..10.0)
                 end

    # Adjust price based on listing type
    price = listing_type == 'selling' ? base_price * rand(1.0..1.3) : base_price * rand(0.7..0.9)

    # Quantity based on unit
    quantity = case unit
               when "kg" then rand(10..1000)
               when "bag" then rand(1..50)
               when "ton" then rand(1..10)
               when "crate" then rand(1..30)
               when "bunch" then rand(10..100)
               else rand(10..100)
               end

    # Create the listing
    listing = CropListing.create!(
      user: user,
      crop: crop,
      region: region,
      title: "#{listing_type == 'selling' ? 'Selling' : 'Looking for'} #{crop.name} - #{quantity} #{unit}",
      description: "#{listing_type == 'selling' ? 'I have' : 'I need'} #{quantity} #{unit} of high-quality #{crop.name} #{listing_type == 'selling' ? 'for sale' : 'to buy'}. This is a sample description for this crop listing.",
      price: price.round(2),
      quantity: quantity,
      unit: unit,
      listing_type: listing_type,
      status: status,
      featured: [true, false, false, false, false].sample,
      negotiable: [true, true, false].sample,
      expiry_date: Date.today + rand(7..60).days,
      sold_at: status == :sold ? (Date.today - rand(1..30).days) : nil,
      location: "Local Community, #{region.name}",
      terms: "Standard terms and conditions apply to this listing. Contact the seller for more details."
    )

    # Create some inquiries for this listing
    if listing.active? && listing_type == 'selling'
      rand(0..3).times do
        inquirer = users.reject { |u| u.id == user.id }.sample

        CropListingInquiry.create!(
          user: inquirer,
          crop_listing: listing,
          message: "I'm interested in your #{crop.name}. Can you provide more details about the quality and availability?",
          status: [:pending, :responded, :accepted, :rejected].sample,
          read: [true, false].sample,
          quantity: rand(1..(quantity * 0.8)).round(2),
          offered_price: price * rand(0.8..1.1).round(2),
          responded_at: [nil, Time.current - rand(1..5).days].sample
        )
      end
    end
  end
end

# Create agriculture resources
puts "Creating agriculture resources..."
resource_types = AgricultureResource.resource_types.keys
crops = Crop.all
admin_users = User.where(admin: true).presence || User.first(3)

30.times do
  resource_type = resource_types.sample
  crop = [nil, crops.sample, crops.sample].sample # Some resources are general, some are crop-specific

  title = case resource_type
          when 'article'
            "#{['Guide to', 'Understanding', 'Tips for', 'Best Practices in'].sample} #{crop&.name || 'Farming'} #{['Production', 'Cultivation', 'Management', 'Marketing'].sample}"
          when 'video'
            "#{['How to Grow', 'Cultivating', 'Harvesting', 'Marketing'].sample} #{crop&.name || 'Crops'} in Ghana"
          when 'guide'
            "#{['Complete Guide to', 'Step-by-Step', 'Comprehensive Manual for'].sample} #{crop&.name || 'Agricultural'} #{['Production', 'Farming', 'Management'].sample}"
          when 'tool'
            "#{['Calculator for', 'Tool for', 'Estimator for'].sample} #{crop&.name || 'Farm'} #{['Planning', 'Budgeting', 'Management', 'Analysis'].sample}"
          when 'faq'
            "Frequently Asked Questions about #{crop&.name || 'Farming'} in Ghana"
          when 'pest_disease'
            "#{['Managing', 'Controlling', 'Preventing', 'Treating'].sample} #{['Pests', 'Diseases', 'Weeds'].sample} in #{crop&.name || 'Crops'}"
          end

  content = "This is a sample article about agriculture in Ghana. It contains information about farming practices, crop varieties, and market trends. The content is meant to be educational and informative for farmers and agricultural stakeholders.\n\nGhana's agricultural sector is diverse and includes crops such as maize, rice, cassava, yams, and various fruits and vegetables. The sector employs a significant portion of the population and contributes substantially to the country's GDP.\n\nFarmers face various challenges including climate change, access to markets, and availability of inputs. However, there are also opportunities for growth and innovation in the sector.\n\nThis article would typically contain more detailed information about specific farming techniques, success stories, and recommendations for improving agricultural productivity."

  tags = []
  tags << crop&.name if crop
  tags << crop&.category.to_s.humanize if crop
  tags << ['farming', 'agriculture', 'ghana', 'west africa', 'tropical', 'smallholder', 'commercial'].sample(3)
  tags << ['organic', 'sustainable', 'traditional', 'modern', 'irrigation', 'rainfed'].sample(2)
  tags << ['harvest', 'planting', 'pest control', 'fertilizer', 'soil management', 'marketing', 'storage'].sample(2)
  tags.flatten!

  AgricultureResource.create!(
    title: title,
    content: content,
    crop: crop,
    user: admin_users.sample,
    resource_type: resource_type,
    published: [true, true, true, false].sample,
    featured: [true, false, false, false, false].sample,
    published_at: [nil, Time.current - rand(1..365).days].sample,
    view_count: rand(0..1000),
    external_url: [nil, "https://example.com/resources/#{rand(1000..9999)}"].sample,
    video_url: resource_type == 'video' ? "https://youtube.com/watch?v=#{('a'..'z').to_a.sample(11).join}" : nil,
    tags: tags.join(',')
  )
end

puts "Agriculture data seeding completed!"
