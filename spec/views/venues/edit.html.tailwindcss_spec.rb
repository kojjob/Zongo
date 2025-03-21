require 'rails_helper'

RSpec.describe "venues/edit", type: :view do
  let(:venue) {
    Venue.create!(
      name: "MyString",
      description: "MyText",
      address: "MyString",
      city: "MyString",
      region: "MyString",
      postal_code: "MyString",
      country: "MyString",
      latitude: "9.99",
      longitude: "9.99",
      capacity: 1,
      user: nil,
      facilities: ""
    )
  }

  before(:each) do
    assign(:venue, venue)
  end

  it "renders the edit venue form" do
    render

    assert_select "form[action=?][method=?]", venue_path(venue), "post" do
      assert_select "input[name=?]", "venue[name]"

      assert_select "textarea[name=?]", "venue[description]"

      assert_select "input[name=?]", "venue[address]"

      assert_select "input[name=?]", "venue[city]"

      assert_select "input[name=?]", "venue[region]"

      assert_select "input[name=?]", "venue[postal_code]"

      assert_select "input[name=?]", "venue[country]"

      assert_select "input[name=?]", "venue[latitude]"

      assert_select "input[name=?]", "venue[longitude]"

      assert_select "input[name=?]", "venue[capacity]"

      assert_select "input[name=?]", "venue[user_id]"

      assert_select "input[name=?]", "venue[facilities]"
    end
  end
end
