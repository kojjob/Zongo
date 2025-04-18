require 'rails_helper'

RSpec.describe "event_media/index", type: :view do
  let(:event) { create(:event) }

  before(:each) do
    assign(:event_media, [
      EventMedium.create!(
        event: event,
        media_type: 2,
        title: "Title",
        description: "MyText",
        is_featured: false,
        display_order: 3
      ),
      EventMedium.create!(
        event: event,
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
    # Check for event ID
    assert_select cell_selector, text: Regexp.new(event.id.to_s), count: 2
    # User ID has been removed
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Title".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(false.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
  end
end
