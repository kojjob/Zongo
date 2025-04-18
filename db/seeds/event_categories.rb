# Create event categories
puts "Creating event categories..."

# Main categories
categories = [
  "Music & Entertainment",
  "Business & Professional",
  "Food & Drink",
  "Community & Culture",
  "Arts & Crafts",
  "Sports & Fitness",
  "Health & Wellness",
  "Science & Technology",
  "Travel & Outdoor",
  "Charity & Causes",
  "Education & Learning",
  "Seasonal & Holiday",
  "Government & Politics",
  "Fashion & Beauty",
  "Home & Lifestyle",
  "Family & Kids",
  "Religion & Spirituality",
  "Other"
]

# Create the categories
categories.each do |name|
  EventCategory.find_or_create_by!(name: name)
end

puts "Created #{EventCategory.count} event categories"
