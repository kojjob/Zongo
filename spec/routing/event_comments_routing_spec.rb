require "rails_helper"

RSpec.describe EventCommentsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/event_comments").to route_to("event_comments#index")
    end

    it "routes to #new" do
      expect(get: "/event_comments/new").to route_to("event_comments#new")
    end

    it "routes to #show" do
      expect(get: "/event_comments/1").to route_to("event_comments#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/event_comments/1/edit").to route_to("event_comments#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/event_comments").to route_to("event_comments#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/event_comments/1").to route_to("event_comments#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/event_comments/1").to route_to("event_comments#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/event_comments/1").to route_to("event_comments#destroy", id: "1")
    end
  end
end
