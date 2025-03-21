require 'rails_helper'

RSpec.describe "event_favorites/index", type: :view do
  before(:each) do
    assign(:event_favorites, [
      EventFavorite.create!(
        event: nil,
        user: nil
      ),
      EventFavorite.create!(
        event: nil,
        user: nil
      )
    ])
  end

  it "renders a list of event_favorites" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
  end
end
