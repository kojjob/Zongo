module EventsHelper
  # Returns appropriate CSS classes for category badges
  def category_color_class(category)
    case category.name.downcase
    when /music/, /art/, /concert/, /festival/
      "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-300"
    when /food/, /drink/, /dining/, /restaurant/
      "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300"
    when /sport/, /fitness/, /game/, /match/
      "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300"
    when /tech/, /technology/, /coding/, /programming/
      "bg-indigo-100 text-indigo-800 dark:bg-indigo-900 dark:text-indigo-300"
    when /business/, /networking/, /conference/
      "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300"
    when /education/, /workshop/, /seminar/, /class/
      "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300"
    when /health/, /wellness/, /medical/
      "bg-teal-100 text-teal-800 dark:bg-teal-900 dark:text-teal-300"
    when /charity/, /fundraiser/, /volunteer/
      "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300"
    when /family/, /kids/, /children/
      "bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-300"
    when /travel/, /trip/, /tourism/
      "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300"
    else
      "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300" # Default
    end
  end
  
  # Generate Google Calendar link
  def google_calendar_link(event)
    dates = format_dates_for_google(event.start_time, event.end_time)
    location = event.venue&.address.present? ? CGI.escape(event.venue.address) : ''
    title = CGI.escape(event.title)
    details = CGI.escape(event.short_description.to_s)
    
    "https://calendar.google.com/calendar/render?action=TEMPLATE&text=#{title}&dates=#{dates}&details=#{details}&location=#{location}&sf=true&output=xml"
  end
  
  # Generate iCal/Apple Calendar link
  def ical_link(event)
    title = CGI.escape(event.title)
    dates = format_dates_for_ical(event.start_time, event.end_time)
    location = CGI.escape(event.venue&.address.to_s)
    details = CGI.escape(event.short_description.to_s)
    
    "data:text/calendar;charset=utf8,BEGIN:VCALENDAR%0AVERSION:2.0%0ABEGIN:VEVENT%0ADTSTART:#{dates[:start]}%0ADTEND:#{dates[:end]}%0ASUMMARY:#{title}%0ADESCRIPTION:#{details}%0ALOCATION:#{location}%0AEND:VEVENT%0AEND:VCALENDAR"
  end
  
  # Generate Outlook Calendar link
  def outlook_calendar_link(event)
    dates = format_dates_for_outlook(event.start_time, event.end_time)
    location = CGI.escape(event.venue&.address.to_s)
    title = CGI.escape(event.title)
    details = CGI.escape(event.short_description.to_s)
    
    "https://outlook.office.com/calendar/0/deeplink/compose?subject=#{title}&body=#{details}&startdt=#{dates[:start]}&enddt=#{dates[:end]}&location=#{location}&path=%2Fcalendar%2Faction%2Fcompose&rru=addevent"
  end
  
  # Generate Yahoo Calendar link
  def yahoo_calendar_link(event)
    title = CGI.escape(event.title)
    dates = format_dates_for_yahoo(event.start_time, event.end_time)
    location = CGI.escape(event.venue&.address.to_s)
    details = CGI.escape(event.short_description.to_s)
    
    "https://calendar.yahoo.com/?v=60&title=#{title}&st=#{dates[:start]}&et=#{dates[:end]}&desc=#{details}&in_loc=#{location}"
  end
  
  private
  
  # Format dates for Google Calendar
  def format_dates_for_google(start_time, end_time)
    start_str = start_time.strftime('%Y%m%dT%H%M%S')
    end_str = end_time.strftime('%Y%m%dT%H%M%S')
    
    "#{start_str}/#{end_str}"
  end
  
  # Format dates for iCal/Apple Calendar
  def format_dates_for_ical(start_time, end_time)
    start_str = start_time.strftime('%Y%m%dT%H%M%S')
    end_str = end_time.strftime('%Y%m%dT%H%M%S')
    
    { start: start_str, end: end_str }
  end
  
  # Format dates for Outlook Calendar
  def format_dates_for_outlook(start_time, end_time)
    start_str = start_time.strftime('%Y-%m-%dT%H:%M:%S')
    end_str = end_time.strftime('%Y-%m-%dT%H:%M:%S')
    
    { start: start_str, end: end_str }
  end
  
  # Format dates for Yahoo Calendar
  def format_dates_for_yahoo(start_time, end_time)
    start_str = start_time.strftime('%Y%m%dT%H%M%S')
    end_str = end_time.strftime('%Y%m%dT%H%M%S')
    
    { start: start_str, end: end_str }
  end
end
