require 'rails_helper'

RSpec.describe "event_tickets/edit", type: :view do
  let(:event_ticket) {
    EventTicket.create!(
      user: nil,
      event: nil,
      ticket_type: nil,
      attendance: nil,
      ticket_code: "MyString",
      status: 1,
      amount: "9.99",
      payment_reference: "MyString",
      transaction_id: "MyString"
    )
  }

  before(:each) do
    assign(:event_ticket, event_ticket)
  end

  it "renders the edit event_ticket form" do
    render

    assert_select "form[action=?][method=?]", event_ticket_path(event_ticket), "post" do

      assert_select "input[name=?]", "event_ticket[user_id]"

      assert_select "input[name=?]", "event_ticket[event_id]"

      assert_select "input[name=?]", "event_ticket[ticket_type_id]"

      assert_select "input[name=?]", "event_ticket[attendance_id]"

      assert_select "input[name=?]", "event_ticket[ticket_code]"

      assert_select "input[name=?]", "event_ticket[status]"

      assert_select "input[name=?]", "event_ticket[amount]"

      assert_select "input[name=?]", "event_ticket[payment_reference]"

      assert_select "input[name=?]", "event_ticket[transaction_id]"
    end
  end
end
