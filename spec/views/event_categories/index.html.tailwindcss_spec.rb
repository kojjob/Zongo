require 'rails_helper'

RSpec.describe "event_categories/index", type: :view do
  before(:each) do
    assign(:event_categories, [
      EventCategory.create!(
        name: "Name",
        description: "MyText",
        icon: "Icon",
        parent_category: nil
      ),
      EventCategory.create!(
        name: "Name",
        description: "MyText",
        icon: "Icon",
        parent_category: nil
      )
    ])
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
