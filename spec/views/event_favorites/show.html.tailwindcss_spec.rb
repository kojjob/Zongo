require 'rails_helper'

RSpec.describe "event_favorites/show", type: :view do
  before(:each) do
    assign(:event_favorite, EventFavorite.create!(
      event: nil,
      user: nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
  end
end
