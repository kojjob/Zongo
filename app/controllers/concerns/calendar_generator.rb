require 'icalendar'

module CalendarGenerator
  extend ActiveSupport::Concern
  
  # Generates an ICS (iCalendar) file for an event
  def generate_ics(event)
    calendar = Icalendar::Calendar.new
    calendar.prodid = '-//Zongo//Events Calendar//EN'
    calendar.version = '2.0'
    
    # Create the event entry
    cal_event = Icalendar::Event.new
    cal_event.dtstart = Icalendar::Values::DateTime.new(event.start_time.utc, 'tzid' => 'UTC')
    cal_event.dtend = Icalendar::Values::DateTime.new(event.end_time.utc, 'tzid' => 'UTC')
    cal_event.summary = event.title
    cal_event.description = event.short_description
    cal_event.location = event.formatted_location if event.respond_to?(:formatted_location)
    
    # Add event URL if available
    cal_event.url = event_url(event) if respond_to?(:event_url)
    
    # Generate a unique identifier for the event
    cal_event.uid = "event-#{event.id}@#{request.host}"
    
    # Add organizer if available
    if event.organizer&.respond_to?(:email) && event.organizer&.email.present?
      organizer = Icalendar::Values::CalAddress.new("mailto:#{event.organizer.email}", 
                                                  cn: event.organizer.respond_to?(:full_name) ? event.organizer.full_name : "Event Organizer")
      cal_event.organizer = organizer
    end
    
    # Add a reminder notification 1 day before the event
    alarm = Icalendar::Alarm.new
    alarm.action = "DISPLAY"
    alarm.description = "Reminder: #{event.title}"
    alarm.trigger = "-P1D" # 1 day before
    cal_event.add_alarm(alarm)
    
    # Add to calendar
    calendar.add_event(cal_event)
    
    # Return the calendar
    calendar.to_ical
  end
  
  # Controller action to download an event as an ICS file
  def download_ics
    @event = Event.find_by(id: params[:id]) || Event.find_by(slug: params[:id])
    
    if @event
      # Track this download for analytics
      EventView.create(event: @event, user: current_user, source: 'calendar_download') if defined?(EventView)
      
      # Generate the calendar file
      calendar_data = generate_ics(@event)
      
      # Send the file to the browser
      send_data calendar_data,
                type: 'text/calendar',
                disposition: 'attachment',
                filename: "#{@event.title.parameterize}-event.ics"
    else
      redirect_to events_path, alert: "Event not found"
    end
  end
end
