require 'rails_helper'

RSpec.describe "attendances/edit", type: :view do
  let(:attendance) {
    Attendance.create!(
      user: nil,
      event: nil,
      status: 1,
      additional_info: "MyText",
      form_responses: ""
    )
  }

  before(:each) do
    assign(:attendance, attendance)
  end

  it "renders the edit attendance form" do
    render

    assert_select "form[action=?][method=?]", attendance_path(attendance), "post" do

      assert_select "input[name=?]", "attendance[user_id]"

      assert_select "input[name=?]", "attendance[event_id]"

      assert_select "input[name=?]", "attendance[status]"

      assert_select "textarea[name=?]", "attendance[additional_info]"

      assert_select "input[name=?]", "attendance[form_responses]"
    end
  end
end
