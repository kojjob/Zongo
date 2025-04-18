require 'rails_helper'

RSpec.describe "event_favorites/index", type: :view do
  let(:user) { create(:user) }
  let(:event) { create(:event) }

  before(:each) do
    assign(:event_favorites, [
      EventFavorite.create!(
        event: event,
        user: user
      ),
      EventFavorite.create!(
        event: event,
        user: user
      )
    ])
  end

  it "renders a list of event_favorites" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(event.id.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(user.id.to_s), count: 2
  end
end
