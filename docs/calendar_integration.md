# Calendar Integration

This documentation covers the calendar integration feature for events in the Zongo application.

## Overview

The calendar integration feature allows users to add events to their preferred calendar applications. This includes:

- Google Calendar
- Apple Calendar
- Outlook
- Yahoo Calendar
- Any calendar app that supports ICS files

## Implementation

The calendar integration is implemented through:

1. A reusable calendar dropdown component (`_calendar_dropdown.html.erb`)
2. A Stimulus controller to handle UI interactions (`calendar_dropdown_controller.js`)
3. A dedicated API endpoint for downloading ICS files (`download_ics`)
4. Model methods to help format event data for calendar services
5. A concern (`CalendarGenerator`) for generating standard ICS files

## Usage

### In Templates

To add the calendar dropdown to any view:

```erb
<%= render 'shared/calendar_dropdown', event: @event %>
```

### Calendar URLs

The following calendar services are supported:

- **Google Calendar**: Uses the standard URL format for Google Calendar's add event feature
- **Apple Calendar/iCal**: Uses our own endpoint to generate a proper ICS file
- **Outlook Web**: Uses the Outlook web calendar deeplink format
- **Yahoo Calendar**: Uses the Yahoo Calendar URL format

### Standard ICS File

For calendar apps that support ICS files (Apple Calendar, Outlook desktop, etc.), we provide a direct download link:

```
/events/:event_id/calendar
```

This endpoint generates a properly formatted ICS file with:
- Event title, description, and location
- Correct start and end times in UTC
- A reminder set for 1 day before the event
- A unique identifier for the event
- Organizer information when available

## Technical Details

### CalendarGenerator Concern

This concern handles the generation of standards-compliant ICS files for calendar applications. It includes:

- Proper formatting of date/time values
- Handling of timezones
- Creation of alarms/reminders
- Encoding of special characters
- Generation of unique identifiers

### Model Additions

The `Event` model includes helper methods for calendar integration:

- `url`: Returns the canonical URL for the event
- `to_ical`: Formats the event as an iCalendar entry
- `formatted_location`: Returns a properly formatted location string

### Analytics

When a user downloads an ICS file, we track this action by creating an `EventView` record with `source: 'calendar_download'`. This helps us understand how users are interacting with events.

## Testing

The calendar integration is fully tested in:

- `spec/controllers/events_controller_calendar_spec.rb`

These tests verify:
- The ICS file is generated with the correct content type
- The file contains all necessary event details
- Event views are properly tracked
- Events can be located by ID or slug

## Future Improvements

Potential enhancements for the calendar integration:

1. Add support for recurring events
2. Implement calendar integration for event series
3. Add options for customizing reminders
4. Support for adding events to specific calendars within Google/Apple/Outlook
5. Track which calendar service is most frequently used
