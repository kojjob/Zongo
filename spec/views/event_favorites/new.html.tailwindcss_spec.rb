require 'rails_helper'

RSpec.describe "event_favorites/new", type: :view do
  before(:each) do
    assign(:event_favorite, EventFavorite.new(
      event: nil,
      user: nil
    ))
  end

  it "renders new event_favorite form" do
    render

    assert_select "form[action=?][method=?]", event_favorites_path, "post" do

      assert_select "input[name=?]", "event_favorite[event_id]"

      assert_select "input[name=?]", "event_favorite[user_id]"
    end
  end
end
