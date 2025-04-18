class EventsController < ApplicationController
  include CalendarGenerator
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :set_event, only: [ :show, :edit, :update, :destroy, :attend, :cancel_attendance, :toggle_favorite ]
  before_action :authorize_organizer!, only: [ :edit, :update, :destroy ]

  # GET /events
  def index
    # Build base query for filtering
    base_query = Event.upcoming.includes(:venue, :category, :organizer, :event_media, :attendances)

    # Apply search if provided
    if params[:query].present?
      base_query = base_query.where("title ILIKE ? OR description ILIKE ?", "%#{params[:query]}%", "%#{params[:query]}%")
    end

    # Apply category filter if provided
    if params[:category_id].present?
      base_query = base_query.by_category(params[:category_id])
    end

    # Apply date range filter
    case params[:date_range]
    when "today"
      base_query = base_query.where("DATE(start_time) = ?", Date.current)
    when "tomorrow"
      base_query = base_query.where("DATE(start_time) = ?", Date.current + 1.day)
    when "weekend"
      base_query = base_query.this_weekend
    when "week"
      base_query = base_query.where("start_time BETWEEN ? AND ?", Date.current, Date.current.end_of_week)
    when "month"
      base_query = base_query.where("start_time BETWEEN ? AND ?", Date.current, Date.current.end_of_month)
    end

    # Apply price filter
    if params[:free_only] == "1"
      base_query = base_query.free
    end

    # Apply sorting
    case params[:sort]
    when "created_desc"
      base_query = base_query.order(created_at: :desc)
    when "popularity"
      base_query = base_query.left_joins(:attendances)
                           .group(:'events.id')
                           .order("COUNT(attendances.id) DESC")
    else # "date_asc" (default)
      base_query = base_query.order(start_time: :asc)
    end

    # Featured event - use the event marked as featured or the first upcoming event
    @featured_event = Event.featured.upcoming
                          .includes(:venue, :category, :organizer, :event_media)
                          .first ||
                     Event.upcoming
                          .includes(:venue, :category, :organizer, :event_media)
                          .first

    # Weekend events
    @weekend_events = Event.this_weekend
                          .includes(:venue, :category, :organizer, :event_media, :attendances)
                          .limit(6)

    # Get category IDs, defaulting to nil if categories don't exist yet
    @music_category = Category.find_by(name: "Music & Art")
    @sports_category = Category.find_by(name: "Sports")
    @food_category = Category.find_by(name: "Food & Drink")

    # Get events by category
    @music_events = @music_category ?
                   Event.by_category(@music_category.id)
                        .upcoming
                        .includes(:venue, :category, :organizer, :event_media, :attendances)
                        .limit(6) :
                   Event.none

    @sports_events = @sports_category ?
                    Event.by_category(@sports_category.id)
                         .upcoming
                         .includes(:venue, :category, :organizer, :event_media, :attendances)
                         .limit(6) :
                    Event.none

    @food_events = @food_category ?
                  Event.by_category(@food_category.id)
                       .upcoming
                       .includes(:venue, :category, :organizer, :event_media, :attendances)
                       .limit(6) :
                  Event.none

    # All upcoming events (paginated with filters applied)
    @pagy, @upcoming_events = pagy(base_query, items: 12)

    # Additional data for filters
    @categories = Category.all.order(:name)
    @popular_events = Event.joins(:attendances)
                          .select("events.*, COUNT(attendances.id) as attendance_count")
                          .group("events.id")
                          .order("attendance_count DESC")
                          .limit(5)

    # Respond with appropriate format
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # GET /events/:id
  def show
    @comments = @event.event_comments.visible.includes(:user).order(created_at: :desc)

    # Get similar events by category (fallback if tags don't exist)
    begin
      # Try to use tags if the table exists
      if ActiveRecord::Base.connection.table_exists?("tags") && @event.respond_to?(:tags) && @event.tags.any?
        @similar_events = @event.related_events_by_tags(3)
      else
        # Fallback to category-based similar events
        @similar_events = Event.where(category: @event.category)
                             .where.not(id: @event.id)
                             .upcoming
                             .limit(3)
      end
    rescue ActiveRecord::StatementInvalid => e
      # Handle case where tags table doesn't exist yet
      @similar_events = Event.where(category: @event.category)
                           .where.not(id: @event.id)
                           .upcoming
                           .limit(3)
    end

    # Get popular tags (safely)
    begin
      @popular_tags = ActiveRecord::Base.connection.table_exists?("tags") ? Tag.popular.limit(10) : []
    rescue ActiveRecord::StatementInvalid => e
      @popular_tags = []
    end

    # Record view
    track_event_view

    respond_to do |format|
      format.html
      format.json
      format.ics do
        calendar = generate_ics_calendar
        send_data calendar.to_ical, type: "text/calendar", disposition: "attachment", filename: "#{@event.title.parameterize}.ics"
      end
    end
  end

  # Generate iCalendar format for event
  def generate_ics_calendar
    require "icalendar"
    require "icalendar/tzinfo"

    # Create a new calendar
    cal = Icalendar::Calendar.new

    # Set timezone for event based on app's timezone
    tzid = "UTC" # Default to UTC or use Application.config.time_zone
    tz = TZInfo::Timezone.get(tzid)
    timezone = tz.ical_timezone(Time.now)
    cal.add_timezone timezone

    # Create the event
    event = Icalendar::Event.new
    event.dtstart = Icalendar::Values::DateTime.new(@event.start_time, tzid: tzid)
    event.dtend = Icalendar::Values::DateTime.new(@event.end_time, tzid: tzid)
    event.summary = @event.title
    event.description = @event.description.to_plain_text rescue @event.description.to_s
    event.organizer = Icalendar::Values::CalAddress.new("mailto:#{@event.organizer.email}", cn: @event.organizer.full_name) if @event.organizer.email.present?

    # Add location if available
    if @event.venue.present?
      event.location = [ @event.venue.name, @event.venue.address, @event.venue.city ].compact.join(", ")

      # Add geo coordinates if available
      if @event.venue.latitude.present? && @event.venue.longitude.present?
        event.geo = [ @event.venue.latitude, @event.venue.longitude ]
      end
    end

    # Add URL to the event page
    event.url = event_url(@event)

    # Add a unique UID for the event
    event.uid = "event-#{@event.id}@#{request.host}"

    # Add a timestamp for when the event was created
    event.created = @event.created_at
    event.last_modified = @event.updated_at

    # Add event categories if available
    event.categories = [ @event.category.name ] if @event.category.present?

    # Add event to calendar
    cal.add_event(event)

    # Return the calendar
    cal
  end

  # GET /events/new
  def new
    @event = Event.new
    load_form_dependencies
  end

  # POST /events
  def create
    # Handle creation of new venue if provided
    create_venue_if_needed

    @event = current_user.organized_events.build(event_params)

    # Set event_category_id if not provided
    if @event.event_category_id.blank?
      # Get the first event category or create one if none exist
      @event.event_category_id = EventCategory.first_or_create!(name: 'General').id
    end

    # Set as draft if requested
    @event.status = 0 if params[:draft].present?

    if @event.save
      # Handle image uploads if any
      if params[:event][:images].present?
        params[:event][:images].each_with_index do |image, index|
          # Skip empty entries
          next if image.blank?
          # Skip if not a valid ActionDispatch::Http::UploadedFile or similar object
          next unless image.respond_to?(:content_type) && image.respond_to?(:original_filename)
          # Skip if not an image file
          next unless image.content_type.to_s.start_with?("image/")
          # Set the first image as featured
          is_featured = (index == 0)
          # Create the event medium record
          event_medium = @event.event_media.create(
            media_type: "image",
            user: current_user,
            is_featured: is_featured,
            url: "" # Placeholder, will be replaced by Active Storage
          )
          # Attach the image
          event_medium.image.attach(image)
        end
      end

      # Set appropriate redirect notice based on status
      notice_message = @event.status.zero? ? "Event saved as draft." : "Event published successfully!"
      redirect_to @event, notice: notice_message
    else
      # Re-fetch categories and venues for the form
      load_form_dependencies
      render :new, status: :unprocessable_entity
    end
  end

  # GET /events/:id/edit
  def edit
    load_form_dependencies
  end

  # PATCH/PUT /events/:id
  def update
    # Handle creation of new venue if provided
    create_venue_if_needed

    # Get the event params
    updated_params = event_params

    # Set event_category_id if not provided
    if updated_params[:event_category_id].blank?
      # Get the first event category or create one if none exist
      updated_params[:event_category_id] = EventCategory.first_or_create!(name: 'General').id
    end

    if @event.update(updated_params)
      # Handle image uploads if any
      Rails.logger.debug "Image uploads: #{params[:event][:images].inspect}"
      Rails.logger.debug "Current event media: #{@event.event_media.count}"
      if params[:event][:images].present?
        # Check if this is the first image for the event
        first_image = @event.event_media.empty?

        params[:event][:images].each_with_index do |image, index|
          # Skip empty entries
          next if image.blank?
          # Skip if not a valid ActionDispatch::Http::UploadedFile or similar object
          next unless image.respond_to?(:content_type) && image.respond_to?(:original_filename)
          # Skip if not an image file
          next unless image.content_type.to_s.start_with?("image/")
          # Set as featured if it's the first image ever uploaded for this event
          is_featured = first_image && index == 0
          # Create the event medium record
          event_medium = @event.event_media.create(
            media_type: "image",
            user: current_user,
            is_featured: is_featured,
            url: "" # Placeholder, will be replaced by Active Storage
          )
          # Attach the image
          event_medium.image.attach(image)
          Rails.logger.debug "Attached image to event_medium #{event_medium.id}: #{event_medium.image.attached?}"
        end
      end

      redirect_to @event, notice: "Event updated successfully!"
    else
      # Re-fetch categories and venues for the form
      load_form_dependencies
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /events/:id
  def destroy
    @event.destroy
    redirect_to events_path, notice: "Event deleted successfully!"
  end

  # POST /events/:id/attend
  def attend
    result = EventAttendanceService.new(@event, current_user).attend

    if result.success?
      redirect_to @event, notice: "You are now attending this event!"
    else
      redirect_to @event, alert: result.error
    end
  end

  # DELETE /events/:id/cancel_attendance
  def cancel_attendance
    result = EventAttendanceService.new(@event, current_user).cancel

    if result.success?
      redirect_to @event, notice: "Your attendance has been cancelled."
    else
      redirect_to @event, alert: result.error
    end
  end

  # POST /events/:id/toggle_favorite
  def toggle_favorite
    result = FavoriteService.new(current_user).toggle_favorite(@event)

    respond_to do |format|
      format.html do
        if result.success?
          redirect_to @event, notice: result.data[:favorited] ? "Event added to favorites!" : "Event removed from favorites."
        else
          redirect_to @event, alert: result.error
        end
      end

      format.json do
        if result.success?
          render json: result.data
        else
          render json: { error: result.error }, status: :unprocessable_entity
        end
      end
    end
  end

  # GET /my_events
  def my_events
    @events = current_user.organized_events
                         .includes(:venue, :category, :event_category, :attendances, :event_media)
                         .order(created_at: :desc)

    # Filter events based on tab
    case params[:filter]
    when 'upcoming'
      @events = @events.upcoming
    when 'past'
      @events = @events.past
    when 'drafts'
      @events = @events.where(status: 0)
    end

    # Set active tab
    @active_tab = params[:filter] || 'all'
  end

  private

  def set_event
    # Try to find by friendly ID if available, otherwise fall back to regular find
    begin
      if Event.respond_to?(:friendly)
        @event = Event.friendly.find(params[:id])
      else
        # Fallback to regular find
        @event = Event.find_by(id: params[:id]) || Event.find_by(slug: params[:id])
      end
    rescue ActiveRecord::RecordNotFound
      @event = nil
    end

    unless @event
      flash[:alert] = "Event not found"
      redirect_to events_path
    end
  end

  def event_params
    params.require(:event).permit(
      :title, :description, :short_description, :start_time, :end_time,
      :venue_id, :event_category_id, :category_id, :price, :capacity, :event_type, :is_featured,
      :is_private, :access_code, :status, :slug, :recurrence_type, :recurrence_pattern,
      :tag_list, :is_free
    )
  end

  def authorize_organizer!
    unless current_user == @event.organizer
      flash[:alert] = "You don't have permission to manage this event."
      redirect_to @event
    end
  end

  def load_form_dependencies
    @categories = Category.all.order(:name)
    @event_categories = EventCategory.all.order(:name)

    # Create a default event category if none exist
    if @event_categories.empty?
      @event_categories = [EventCategory.create!(name: 'General')]
    end

    @venues = Venue.all.order(:name)
  end

  def create_venue_if_needed
    return unless params[:venue].present? &&
                  params[:venue][:name].present? &&
                  params[:venue][:address].present? &&
                  params[:venue][:city].present?

    # Create the new venue
    venue = Venue.new(venue_params)
    venue.user = current_user

    if venue.save
      # Update the event params to use this venue
      params[:event][:venue_id] = venue.id
    end
  end

  def venue_params
    params.require(:venue).permit(
      :name, :address, :city, :region, :phone, :capacity
    )
  end

  def track_event_view
    # Don't track views from the organizer
    return if @event.organizer == current_user

    # Get IP address, handle proxies
    ip = request.remote_ip

    # Register the view with additional tracking data
    EventView.register(
      @event.id,
      ip,
      current_user&.id,
      request.user_agent,
      request.referer
    )
  end
end
