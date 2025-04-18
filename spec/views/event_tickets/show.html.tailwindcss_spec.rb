require 'rails_helper'

RSpec.describe "event_tickets/show", type: :view do
  let(:user) { create(:user) }
  let(:event) { create(:event) }
  let(:ticket_type) { create(:ticket_type, event: event) }
  let(:attendance) { create(:attendance, user: user, event: event) }

  before(:each) do
    assign(:event_ticket, EventTicket.create!(
      user: user,
      event: event,
      ticket_type: ticket_type,
      attendance: attendance,
      ticket_code: "Ticket Code",
      status: 2,
      amount: "9.99",
      payment_reference: "Payment Reference",
      transaction_id: "Transaction"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/#{user.id}/)
    expect(rendered).to match(/#{event.id}/)
    expect(rendered).to match(/#{ticket_type.id}/)
    expect(rendered).to match(/#{attendance.id}/)
    expect(rendered).to match(/Ticket Code/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/Payment Reference/)
    expect(rendered).to match(/Transaction/)
  end
end
