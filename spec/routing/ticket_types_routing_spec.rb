require "rails_helper"

RSpec.describe TicketTypesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/ticket_types").to route_to("ticket_types#index")
    end

    it "routes to #new" do
      expect(get: "/ticket_types/new").to route_to("ticket_types#new")
    end

    it "routes to #show" do
      expect(get: "/ticket_types/1").to route_to("ticket_types#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/ticket_types/1/edit").to route_to("ticket_types#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/ticket_types").to route_to("ticket_types#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/ticket_types/1").to route_to("ticket_types#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/ticket_types/1").to route_to("ticket_types#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/ticket_types/1").to route_to("ticket_types#destroy", id: "1")
    end
  end
end
