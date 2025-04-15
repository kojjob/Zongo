require 'rails_helper'

RSpec.describe "event_comments/index", type: :view do
  before(:each) do
    assign(:event_comments, [
      EventComment.create!(
        event: nil,
        user: nil,
        parent_comment: nil,
        content: "MyText",
        is_hidden: false,
        likes_count: 2
      ),
      EventComment.create!(
        event: nil,
        user: nil,
        parent_comment: nil,
        content: "MyText",
        is_hidden: false,
        likes_count: 2
      )
    ])
  end

  it "renders a list of event_comments" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(false.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
  end
end
