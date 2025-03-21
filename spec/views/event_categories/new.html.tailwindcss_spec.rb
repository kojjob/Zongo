require 'rails_helper'

RSpec.describe "event_categories/new", type: :view do
  before(:each) do
    assign(:event_category, EventCategory.new(
      name: "MyString",
      description: "MyText",
      icon: "MyString",
      parent_category: nil
    ))
  end

  it "renders new event_category form" do
    render

    assert_select "form[action=?][method=?]", event_categories_path, "post" do
      assert_select "input[name=?]", "event_category[name]"

      assert_select "textarea[name=?]", "event_category[description]"

      assert_select "input[name=?]", "event_category[icon]"

      assert_select "input[name=?]", "event_category[parent_category_id]"
    end
  end
end
