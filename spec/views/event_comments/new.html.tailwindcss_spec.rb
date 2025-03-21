require 'rails_helper'

RSpec.describe "event_comments/new", type: :view do
  before(:each) do
    assign(:event_comment, EventComment.new(
      event: nil,
      user: nil,
      parent_comment: nil,
      content: "MyText",
      is_hidden: false,
      likes_count: 1
    ))
  end

  it "renders new event_comment form" do
    render

    assert_select "form[action=?][method=?]", event_comments_path, "post" do
      assert_select "input[name=?]", "event_comment[event_id]"

      assert_select "input[name=?]", "event_comment[user_id]"

      assert_select "input[name=?]", "event_comment[parent_comment_id]"

      assert_select "textarea[name=?]", "event_comment[content]"

      assert_select "input[name=?]", "event_comment[is_hidden]"

      assert_select "input[name=?]", "event_comment[likes_count]"
    end
  end
end
