require 'rails_helper'

RSpec.describe "event_tickets/index", type: :view do
  before(:each) do
    assign(:event_tickets, [
      EventTicket.create!(
        user: nil,
        event: nil,
        ticket_type: nil,
        attendance: nil,
        ticket_code: "Ticket Code",
        status: 2,
        amount: "9.99",
        payment_reference: "Payment Reference",
        transaction_id: "Transaction"
      ),
      EventTicket.create!(
        user: nil,
        event: nil,
        ticket_type: nil,
        attendance: nil,
        ticket_code: "Ticket Code",
        status: 2,
        amount: "9.99",
        payment_reference: "Payment Reference",
        transaction_id: "Transaction"
      )
    ])
  end

  it "renders a list of event_tickets" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Ticket Code".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Payment Reference".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Transaction".to_s), count: 2
  end
end
