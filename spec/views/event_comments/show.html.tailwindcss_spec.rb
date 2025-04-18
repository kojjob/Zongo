require 'rails_helper'

RSpec.describe "event_comments/show", type: :view do
  let(:user) { create(:user) }
  let(:event) { create(:event) }

  before(:each) do
    assign(:event_comment, EventComment.create!(
      event: event,
      user: user,
      parent_comment: nil,
      content: "MyText",
      is_hidden: false,
      likes_count: 2
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/#{event.id}/)
    expect(rendered).to match(/#{user.id}/)
    expect(rendered).to match(//)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/2/)
  end
end
