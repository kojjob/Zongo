require "rails_helper"

RSpec.describe EventFavoritesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/event_favorites").to route_to("event_favorites#index")
    end

    it "routes to #new" do
      expect(get: "/event_favorites/new").to route_to("event_favorites#new")
    end

    it "routes to #show" do
      expect(get: "/event_favorites/1").to route_to("event_favorites#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/event_favorites/1/edit").to route_to("event_favorites#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/event_favorites").to route_to("event_favorites#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/event_favorites/1").to route_to("event_favorites#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/event_favorites/1").to route_to("event_favorites#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/event_favorites/1").to route_to("event_favorites#destroy", id: "1")
    end
  end
end
