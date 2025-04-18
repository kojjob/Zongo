require 'rails_helper'

RSpec.describe "event_favorites/show", type: :view do
  let(:user) { create(:user) }
  let(:event) { create(:event) }

  before(:each) do
    assign(:event_favorite, EventFavorite.create!(
      event: event,
      user: user
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/#{event.id}/)
    expect(rendered).to match(/#{user.id}/)
  end
end
