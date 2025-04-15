require 'rails_helper'

RSpec.describe "events/new", type: :view do
  before(:each) do
    assign(:event, Event.new(
      title: "MyString",
      description: "MyText",
      short_description: "MyText",
      capacity: 1,
      status: 1,
      is_featured: false,
      is_private: false,
      access_code: "MyString",
      slug: "MyString",
      organizer: nil,
      event_category: nil,
      venue: nil,
      recurrence_type: 1,
      recurrence_pattern: "",
      parent_event: nil,
      favorites_count: 1,
      views_count: 1,
      custom_fields: ""
    ))
  end

  it "renders new event form" do
    render

    assert_select "form[action=?][method=?]", events_path, "post" do
      assert_select "input[name=?]", "event[title]"

      assert_select "textarea[name=?]", "event[description]"

      assert_select "textarea[name=?]", "event[short_description]"

      assert_select "input[name=?]", "event[capacity]"

      assert_select "input[name=?]", "event[status]"

      assert_select "input[name=?]", "event[is_featured]"

      assert_select "input[name=?]", "event[is_private]"

      assert_select "input[name=?]", "event[access_code]"

      assert_select "input[name=?]", "event[slug]"

      assert_select "input[name=?]", "event[organizer_id]"

      assert_select "input[name=?]", "event[event_category_id]"

      assert_select "input[name=?]", "event[venue_id]"

      assert_select "input[name=?]", "event[recurrence_type]"

      assert_select "input[name=?]", "event[recurrence_pattern]"

      assert_select "input[name=?]", "event[parent_event_id]"

      assert_select "input[name=?]", "event[favorites_count]"

      assert_select "input[name=?]", "event[views_count]"

      assert_select "input[name=?]", "event[custom_fields]"
    end
  end
end
