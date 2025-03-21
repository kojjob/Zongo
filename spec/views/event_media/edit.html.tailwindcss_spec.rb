require 'rails_helper'

RSpec.describe "event_media/edit", type: :view do
  let(:event_medium) {
    EventMedium.create!(
      event: nil,
      user: nil,
      media_type: 1,
      title: "MyString",
      description: "MyText",
      is_featured: false,
      display_order: 1
    )
  }

  before(:each) do
    assign(:event_medium, event_medium)
  end

  it "renders the edit event_medium form" do
    render

    assert_select "form[action=?][method=?]", event_medium_path(event_medium), "post" do

      assert_select "input[name=?]", "event_medium[event_id]"

      assert_select "input[name=?]", "event_medium[user_id]"

      assert_select "input[name=?]", "event_medium[media_type]"

      assert_select "input[name=?]", "event_medium[title]"

      assert_select "textarea[name=?]", "event_medium[description]"

      assert_select "input[name=?]", "event_medium[is_featured]"

      assert_select "input[name=?]", "event_medium[display_order]"
    end
  end
end
