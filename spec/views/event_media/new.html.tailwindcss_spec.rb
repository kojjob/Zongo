require 'rails_helper'

RSpec.describe "event_media/new", type: :view do
  let(:event) { create(:event) }

  before(:each) do
    assign(:event_medium, EventMedium.new(
      event: event,
      media_type: 1,
      title: "MyString",
      description: "MyText",
      is_featured: false,
      display_order: 1
    ))
  end

  it "renders new event_medium form" do
    render

    assert_select "form[action=?][method=?]", event_media_path, "post" do
      assert_select "input[name=?]", "event_medium[event_id]"

      # User ID has been removed
      # assert_select "input[name=?]", "event_medium[user_id]"

      assert_select "input[name=?]", "event_medium[media_type]"

      assert_select "input[name=?]", "event_medium[title]"

      assert_select "textarea[name=?]", "event_medium[description]"

      assert_select "input[name=?]", "event_medium[is_featured]"

      assert_select "input[name=?]", "event_medium[display_order]"
    end
  end
end
