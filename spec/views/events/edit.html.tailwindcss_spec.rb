require 'rails_helper'

RSpec.describe "events/edit", type: :view do
  let(:event) { create(:event) }

  before(:each) do
    assign(:event, event)
  end

  it "renders the edit event form" do
    render

    assert_select "form[action=?][method=?]", event_path(event), "post" do
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

      # event_category_id has been removed or renamed
      # assert_select "input[name=?]", "event[event_category_id]"

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
