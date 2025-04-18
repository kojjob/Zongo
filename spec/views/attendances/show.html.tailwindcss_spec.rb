require 'rails_helper'

RSpec.describe "attendances/show", type: :view do
  let(:user) { create(:user) }
  let(:event) { create(:event) }

  before(:each) do
    assign(:attendance, Attendance.create!(
      user: user,
      event: event,
      status: 2,
      additional_info: "MyText",
      form_responses: ""
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/#{user.id}/)
    expect(rendered).to match(/#{event.id}/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(//)
  end
end
