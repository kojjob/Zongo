require 'rails_helper'

RSpec.describe "event_tickets/show", type: :view do
  before(:each) do
    assign(:event_ticket, EventTicket.create!(
      user: nil,
      event: nil,
      ticket_type: nil,
      attendance: nil,
      ticket_code: "Ticket Code",
      status: 2,
      amount: "9.99",
      payment_reference: "Payment Reference",
      transaction_id: "Transaction"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/Ticket Code/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/Payment Reference/)
    expect(rendered).to match(/Transaction/)
  end
end
