require 'rails_helper'

RSpec.describe EventsController, type: :controller do
  let(:user) { create(:user) }
  let(:event) { create(:event, organizer: user) }
  
  describe "GET #download_ics" do
    before do
      sign_in user
    end
    
    it "returns an ICS file with the correct content type" do
      get :download_ics, params: { id: event.id }
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('text/calendar')
      expect(response.headers['Content-Disposition']).to include("attachment")
      expect(response.headers['Content-Disposition']).to include(".ics")
    end
    
    it "includes event details in the ICS file" do
      get :download_ics, params: { id: event.id }
      
      ics_content = response.body
      
      # Basic checks for required iCalendar components
      expect(ics_content).to include("BEGIN:VCALENDAR")
      expect(ics_content).to include("VERSION:2.0")
      expect(ics_content).to include("BEGIN:VEVENT")
      expect(ics_content).to include("SUMMARY:#{event.title}")
      expect(ics_content).to include("END:VEVENT")
      expect(ics_content).to include("END:VCALENDAR")
      
      # Check for date information
      expect(ics_content).to include("DTSTART")
      expect(ics_content).to include("DTEND")
      
      # Check for alarm/reminder
      expect(ics_content).to include("BEGIN:VALARM")
      expect(ics_content).to include("ACTION:DISPLAY")
      expect(ics_content).to include("END:VALARM")
    end
    
    it "creates an EventView record for analytics" do
      expect {
        get :download_ics, params: { id: event.id }
      }.to change(EventView, :count).by(1)
      
      view = EventView.last
      expect(view.event).to eq(event)
      expect(view.user).to eq(user)
      expect(view.source).to eq('calendar_download')
    end
    
    it "handles events by slug" do
      get :download_ics, params: { id: event.slug }
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to eq('text/calendar')
    end
    
    it "redirects to events_path if event not found" do
      get :download_ics, params: { id: 'non-existent-event' }
      
      expect(response).to redirect_to(events_path)
      expect(flash[:alert]).to eq("Event not found")
    end
  end
end
