require 'rails_helper'

RSpec.describe "attendances/index", type: :view do
  let(:user) { create(:user) }
  let(:event) { create(:event) }

  before(:each) do
    assign(:attendances, [
      Attendance.create!(
        user: user,
        event: event,
        status: 2,
        additional_info: "MyText",
        form_responses: ""
      ),
      Attendance.create!(
        user: user,
        event: event,
        status: 2,
        additional_info: "MyText",
        form_responses: ""
      )
    ])
  end

  it "renders a list of attendances" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(user.id.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(event.id.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("".to_s), count: 2
  end
end
