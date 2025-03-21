# Pagy initializer file - only load if gem is available
begin
  require "pagy"

  # Pagy Variables
  # See https://ddnexus.github.io/pagy/api/pagy#variables
  Pagy::DEFAULT[:items] = 20    # items per page
  Pagy::DEFAULT[:size]  = [ 1, 4, 4, 1 ] # nav bar links

  # Extras
  # See https://ddnexus.github.io/pagy/extras

  # Tailwind extra: Add nav, responsive and compact helpers for Tailwind pagination
  require "pagy/extras/tailwind"

  # When you are done setting your own default freeze it, so it will not get changed accidentally
  Pagy::DEFAULT.freeze
rescue LoadError
  # Pagy gem not available - skip initialization
  puts "Warning: Pagy gem not loaded. Run 'bundle install' to install it."
end
