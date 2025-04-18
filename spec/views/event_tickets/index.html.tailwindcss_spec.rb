require 'rails_helper'

RSpec.describe "event_tickets/index", type: :view do
  let(:user) { create(:user) }
  let(:event) { create(:event) }
  let(:ticket_type) { create(:ticket_type, event: event) }
  let(:attendance) { create(:attendance, user: user, event: event) }

  before(:each) do
    assign(:event_tickets, [
      EventTicket.create!(
        user: user,
        event: event,
        ticket_type: ticket_type,
        attendance: attendance,
        ticket_code: "Ticket Code",
        status: 2,
        amount: "9.99",
        payment_reference: "Payment Reference",
        transaction_id: "Transaction"
      ),
      EventTicket.create!(
        user: user,
        event: event,
        ticket_type: ticket_type,
        attendance: attendance,
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
    assert_select cell_selector, text: Regexp.new(user.id.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(event.id.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(ticket_type.id.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(attendance.id.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Ticket Code".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Payment Reference".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Transaction".to_s), count: 2
  end
end
