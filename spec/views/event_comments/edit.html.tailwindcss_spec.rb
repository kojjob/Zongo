require 'rails_helper'

RSpec.describe "event_comments/edit", type: :view do
  let(:user) { create(:user) }
  let(:event) { create(:event) }
  let(:event_comment) {
    EventComment.create!(
      event: event,
      user: user,
      parent_comment: nil,
      content: "MyText",
      is_hidden: false,
      likes_count: 1
    )
  }

  before(:each) do
    assign(:event_comment, event_comment)
  end

  it "renders the edit event_comment form" do
    render

    assert_select "form[action=?][method=?]", event_comment_path(event_comment), "post" do
      assert_select "input[name=?]", "event_comment[event_id]"

      assert_select "input[name=?]", "event_comment[user_id]"

      assert_select "input[name=?]", "event_comment[parent_comment_id]"

      assert_select "textarea[name=?]", "event_comment[content]"

      assert_select "input[name=?]", "event_comment[is_hidden]"

      assert_select "input[name=?]", "event_comment[likes_count]"
    end
  end
end
