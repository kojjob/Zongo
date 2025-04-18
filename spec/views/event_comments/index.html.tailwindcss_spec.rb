require 'rails_helper'

RSpec.describe "event_comments/index", type: :view do
  let(:user) { create(:user) }
  let(:event) { create(:event) }

  before(:each) do
    assign(:event_comments, [
      EventComment.create!(
        event: event,
        user: user,
        parent_comment: nil,
        content: "MyText",
        is_hidden: false,
        likes_count: 2
      ),
      EventComment.create!(
        event: event,
        user: user,
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
    assert_select cell_selector, text: Regexp.new(event.id.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(user.id.to_s), count: 2
    # Skip parent_comment assertion as it's nil
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(false.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
  end
end
