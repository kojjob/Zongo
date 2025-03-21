require 'rails_helper'

RSpec.describe "event_tickets/new", type: :view do
  before(:each) do
    assign(:event_ticket, EventTicket.new(
      user: nil,
      event: nil,
      ticket_type: nil,
      attendance: nil,
      ticket_code: "MyString",
      status: 1,
      amount: "9.99",
      payment_reference: "MyString",
      transaction_id: "MyString"
    ))
  end

  it "renders new event_ticket form" do
    render

    assert_select "form[action=?][method=?]", event_tickets_path, "post" do

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
