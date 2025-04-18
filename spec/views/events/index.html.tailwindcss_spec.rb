require 'rails_helper'

RSpec.describe "events/index", type: :view do
  before(:each) do
    assign(:events, [
      create(:event, title: "Title"),
      create(:event, title: "Title")
    ])
  end

  it "renders a list of events" do
    render
    cell_selector = 'div>p'
    # Just check for the title which we explicitly set
    assert_select cell_selector, text: Regexp.new("Title".to_s), count: 2
  end
end
