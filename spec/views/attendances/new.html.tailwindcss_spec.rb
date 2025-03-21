require 'rails_helper'

RSpec.describe "attendances/new", type: :view do
  before(:each) do
    assign(:attendance, Attendance.new(
      user: nil,
      event: nil,
      status: 1,
      additional_info: "MyText",
      form_responses: ""
    ))
  end

  it "renders new attendance form" do
    render

    assert_select "form[action=?][method=?]", attendances_path, "post" do
      assert_select "input[name=?]", "attendance[user_id]"

      assert_select "input[name=?]", "attendance[event_id]"

      assert_select "input[name=?]", "attendance[status]"

      assert_select "textarea[name=?]", "attendance[additional_info]"

      assert_select "input[name=?]", "attendance[form_responses]"
    end
  end
end
