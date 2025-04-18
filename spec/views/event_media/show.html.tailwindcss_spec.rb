require 'rails_helper'

RSpec.describe "event_media/show", type: :view do
  let(:event) { create(:event) }

  before(:each) do
    assign(:event_medium, EventMedium.create!(
      event: event,
      media_type: 2,
      title: "Title",
      description: "MyText",
      is_featured: false,
      display_order: 3
    ))
  end

  it "renders attributes in <p>" do
    render
    # Event ID
    expect(rendered).to match(/#{event.id}/)
    # User ID has been removed
    expect(rendered).to match(/2/)
    expect(rendered).to match(/Title/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/3/)
  end
end
