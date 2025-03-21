require 'rails_helper'

RSpec.describe "event_favorites/edit", type: :view do
  let(:event_favorite) {
    EventFavorite.create!(
      event: nil,
      user: nil
    )
  }

  before(:each) do
    assign(:event_favorite, event_favorite)
  end

  it "renders the edit event_favorite form" do
    render

    assert_select "form[action=?][method=?]", event_favorite_path(event_favorite), "post" do
      assert_select "input[name=?]", "event_favorite[event_id]"

      assert_select "input[name=?]", "event_favorite[user_id]"
    end
  end
end
