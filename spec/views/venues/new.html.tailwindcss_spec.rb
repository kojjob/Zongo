require 'rails_helper'

RSpec.describe "venues/new", type: :view do
  before(:each) do
    assign(:venue, Venue.new(
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
    ))
  end

  it "renders new venue form" do
    render

    assert_select "form[action=?][method=?]", venues_path, "post" do

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
