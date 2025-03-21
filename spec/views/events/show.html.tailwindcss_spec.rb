require 'rails_helper'

RSpec.describe "events/show", type: :view do
  before(:each) do
    assign(:event, Event.create!(
      title: "Title",
      description: "MyText",
      short_description: "MyText",
      capacity: 2,
      status: 3,
      is_featured: false,
      is_private: false,
      access_code: "Access Code",
      slug: "Slug",
      organizer: nil,
      event_category: nil,
      venue: nil,
      recurrence_type: 4,
      recurrence_pattern: "",
      parent_event: nil,
      favorites_count: 5,
      views_count: 6,
      custom_fields: ""
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Title/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/Access Code/)
    expect(rendered).to match(/Slug/)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/4/)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/5/)
    expect(rendered).to match(/6/)
    expect(rendered).to match(//)
  end
end
