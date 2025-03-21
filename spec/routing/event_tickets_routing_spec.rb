require "rails_helper"

RSpec.describe EventTicketsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/event_tickets").to route_to("event_tickets#index")
    end

    it "routes to #new" do
      expect(get: "/event_tickets/new").to route_to("event_tickets#new")
    end

    it "routes to #show" do
      expect(get: "/event_tickets/1").to route_to("event_tickets#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/event_tickets/1/edit").to route_to("event_tickets#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/event_tickets").to route_to("event_tickets#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/event_tickets/1").to route_to("event_tickets#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/event_tickets/1").to route_to("event_tickets#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/event_tickets/1").to route_to("event_tickets#destroy", id: "1")
    end
  end
end
