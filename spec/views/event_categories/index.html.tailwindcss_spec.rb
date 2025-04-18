require 'rails_helper'

RSpec.describe "event_categories/index", type: :view do
  before(:each) do
    # Create some root categories
    root_category1 = EventCategory.create!(
      name: "Root Category 1 #{rand(1000)}",
      description: "MyText",
      icon: "Icon",
      parent_category: nil
    )
    root_category2 = EventCategory.create!(
      name: "Root Category 2 #{rand(1000)}",
      description: "MyText",
      icon: "Icon",
      parent_category: nil
    )
    # Create a subcategory (optional, but good for testing hierarchy if needed)
    # sub_category = EventCategory.create!(
    #   name: "Sub Category #{rand(1000)}",
    #   description: "MyText",
    #   icon: "Icon",
    #   parent_category: root_category1
    # )

    # Assign instance variables needed by the view
    assign(:event_categories, [root_category1, root_category2]) # Assign all categories if needed elsewhere
    assign(:root_categories, [root_category1, root_category2]) # Assign the root categories specifically
  end

  it "renders a list of event_categories" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Icon".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
  end
end
