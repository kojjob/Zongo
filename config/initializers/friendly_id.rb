# FriendlyId Global Configuration
#
# Use this to set up shared configuration options for your entire application.
# Any of the configuration options shown here can also be applied to single
# models by passing arguments to the `friendly_id` class method or defining
# methods in your model.
#
# To learn more, check out the guide:
#
# http://norman.github.io/friendly_id/file.Guide.html

begin
  if defined?(FriendlyId)
    FriendlyId.defaults do |config|
      # ## Reserved Words
      #
      # Some words could conflict with Rails's routes when used as slugs, or are
      # undesirable to allow as slugs. Edit this list as needed for your app.
      config.use :reserved
      
      config.reserved_words = %w(new edit index session login logout users admin
        stylesheets assets javascripts images)
        
      # This adds an option to treat reserved words as conflicts rather than exceptions.
      # When there is no good candidate, a UUID will be appended, matching the existing
      # conflict behavior.
      config.treat_reserved_as_conflict = true
    end
  else
    puts "FriendlyId gem not loaded. Add it to your Gemfile: gem 'friendly_id'"
  end
rescue => e
  puts "Error initializing FriendlyId: #{e.message}"
end
