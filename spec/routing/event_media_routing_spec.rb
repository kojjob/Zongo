require "rails_helper"

RSpec.describe EventMediaController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/event_media").to route_to("event_media#index")
    end

    it "routes to #new" do
      expect(get: "/event_media/new").to route_to("event_media#new")
    end

    it "routes to #show" do
      expect(get: "/event_media/1").to route_to("event_media#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/event_media/1/edit").to route_to("event_media#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/event_media").to route_to("event_media#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/event_media/1").to route_to("event_media#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/event_media/1").to route_to("event_media#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/event_media/1").to route_to("event_media#destroy", id: "1")
    end
  end
end
