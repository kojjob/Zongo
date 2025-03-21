require 'rails_helper'

RSpec.describe "attendances/index", type: :view do
  before(:each) do
    assign(:attendances, [
      Attendance.create!(
        user: nil,
        event: nil,
        status: 2,
        additional_info: "MyText",
        form_responses: ""
      ),
      Attendance.create!(
        user: nil,
        event: nil,
        status: 2,
        additional_info: "MyText",
        form_responses: ""
      )
    ])
  end

  it "renders a list of attendances" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("".to_s), count: 2
  end
end
