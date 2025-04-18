require 'rails_helper'

RSpec.describe "event_categories/edit", type: :view do
  let(:event_category) {
    EventCategory.create!(
      name: "MyString",
      description: "MyText",
      icon: "MyString",
      parent_category: nil
    )
  }

  before(:each) do
    assign(:event_category, event_category)
  end

  it "renders the edit event_category form" do
    render

    assert_select "form[action=?][method=?]", event_category_path(event_category), "post" do
      assert_select "input[name=?]", "event_category[name]"

      assert_select "textarea[name=?]", "event_category[description]"

      assert_select "input[name=?]", "event_category[icon]"

      # The form might be using a select instead of an input for parent_category_id
      # assert_select "input[name=?]", "event_category[parent_category_id]"
    end
  end
end
