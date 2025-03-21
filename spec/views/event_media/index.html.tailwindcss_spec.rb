require 'rails_helper'

RSpec.describe "event_media/index", type: :view do
  before(:each) do
    assign(:event_media, [
      EventMedium.create!(
        event: nil,
        user: nil,
        media_type: 2,
        title: "Title",
        description: "MyText",
        is_featured: false,
        display_order: 3
      ),
      EventMedium.create!(
        event: nil,
        user: nil,
        media_type: 2,
        title: "Title",
        description: "MyText",
        is_featured: false,
        display_order: 3
      )
    ])
  end

  it "renders a list of event_media" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Title".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(false.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
  end
end
