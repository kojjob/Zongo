module CalendarHelper
  # Generate Google Calendar link
  def google_calendar_link(event)
    base_url = "https://calendar.google.com/calendar/render"
    params = {
      action: "TEMPLATE",
      text: event.title,
      dates: "#{format_datetime_for_google(event.start_time)}/#{format_datetime_for_google(event.end_time)}",
      details: event.description.to_s.truncate(1000),
      location: event.venue&.address.to_s,
      sf: true,
      output: "xml"
    }

    "#{base_url}?#{params.to_query}"
  end

  # Generate Apple/iCal Calendar link
  def ical_calendar_link(event)
    base_url = event_url(event, format: :ics)
    base_url
  end

  # Generate Outlook Calendar link
  def outlook_calendar_link(event)
    base_url = "https://outlook.live.com/calendar/0/deeplink/compose"
    params = {
      subject: event.title,
      startdt: event.start_time.iso8601,
      enddt: event.end_time.iso8601,
      body: event.description.to_s.truncate(1000),
      location: event.venue&.address.to_s,
      path: "/calendar/action/compose"
    }

    "#{base_url}?#{params.to_query}"
  end

  # Generate Yahoo Calendar link
  def yahoo_calendar_link(event)
    base_url = "https://calendar.yahoo.com/"
    params = {
      v: 60,
      title: event.title,
      st: event.start_time.strftime("%Y%m%dT%H%M%S"),
      et: event.end_time.strftime("%Y%m%dT%H%M%S"),
      desc: event.description.to_s.truncate(500),
      in_loc: event.venue&.address.to_s
    }

    "#{base_url}?#{params.to_query}"
  end

  private

  # Format datetime for Google Calendar (YYYYMMDDTHHMMSSZ)
  def format_datetime_for_google(datetime)
    datetime.utc.strftime("%Y%m%dT%H%M%SZ")
  end
end
