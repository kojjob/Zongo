require 'rails_helper'

RSpec.describe "venues/index", type: :view do
  let(:user) { create(:user) }

  before(:each) do
    assign(:venues, [
      Venue.create!(
        name: "Name",
        description: "MyText",
        address: "Address",
        city: "City",
        region: "Region",
        postal_code: "Postal Code",
        country: "Country",
        latitude: "9.99",
        longitude: "9.99",
        capacity: 2,
        user: user,
        facilities: ""
      ),
      Venue.create!(
        name: "Name",
        description: "MyText",
        address: "Address",
        city: "City",
        region: "Region",
        postal_code: "Postal Code",
        country: "Country",
        latitude: "9.99",
        longitude: "9.99",
        capacity: 2,
        user: user,
        facilities: ""
      )
    ])
  end

  it "renders a list of venues" do
    render
    # Use a more general selector that will match the actual HTML structure
    # Use assert_select for more specific targeting of venue names.
    # This looks for common elements containing the exact text "Name".
    # Adjust the selector ('div, p, span, td') if the view uses different elements.
    assert_select 'div, p, span, td', text: 'Name', count: 2

    # Keep the broader checks for other attributes for now, but ideally these
    # should also use more specific selectors if possible.
    expect(rendered).to include("MyText").twice
    expect(rendered).to include("Address").twice
    expect(rendered).to include("City").twice
    expect(rendered).to include("Region").twice
    expect(rendered).to include("Postal Code").twice
    expect(rendered).to include("Country").twice
  end
end
