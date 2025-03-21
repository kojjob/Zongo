require 'rails_helper'

RSpec.describe "venues/show", type: :view do
  before(:each) do
    assign(:venue, Venue.create!(
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
      user: nil,
      facilities: ""
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/Address/)
    expect(rendered).to match(/City/)
    expect(rendered).to match(/Region/)
    expect(rendered).to match(/Postal Code/)
    expect(rendered).to match(/Country/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
  end
end
