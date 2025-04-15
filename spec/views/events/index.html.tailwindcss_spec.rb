require 'rails_helper'

RSpec.describe "events/index", type: :view do
  before(:each) do
    assign(:events, [
      Event.create!(
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
      ),
      Event.create!(
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
      )
    ])
  end

  it "renders a list of events" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Title".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(false.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(false.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Access Code".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Slug".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(4.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(5.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(6.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("".to_s), count: 2
  end
end
