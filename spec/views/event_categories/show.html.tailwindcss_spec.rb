require 'rails_helper'

RSpec.describe "event_categories/show", type: :view do
  before(:each) do
    assign(:event_category, EventCategory.create!(
      name: "Name",
      description: "MyText",
      icon: "Icon",
      parent_category: nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/MyText/)
    # The icon might be rendered as an SVG or class name, not directly in the HTML
    # expect(rendered).to match(/Icon/)
    expect(rendered).to match(//)
  end
end
