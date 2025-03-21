require 'rails_helper'

RSpec.describe "attendances/show", type: :view do
  before(:each) do
    assign(:attendance, Attendance.create!(
      user: nil,
      event: nil,
      status: 2,
      additional_info: "MyText",
      form_responses: ""
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(//)
  end
end
