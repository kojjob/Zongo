require 'rails_helper'

RSpec.describe "venues/index", type: :view do
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
        user: nil,
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
        user: nil,
        facilities: ""
      )
    ])
  end

  it "renders a list of venues" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Address".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("City".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Region".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Postal Code".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Country".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("".to_s), count: 2
  end
end
