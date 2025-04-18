require 'rails_helper'

RSpec.describe "ticket_types/show", type: :view do
  let(:event) { create(:event) }

  let(:event) { create(:event) }

  let(:event) { create(:event) }

  before(:each) do
    assign(:ticket_type, TicketType.create!(
      event: event,
      name: "Name",
      description: "MyText",
      price: "9.99",
      quantity: 2,
      sold_count: 3,
      max_per_user: 4,
      transferable: false
    ))
  end

  it "renders attributes in <p>" do
    render
    # Event ID
    expect(rendered).to match(/#{event.id}/)
    expect(rendered).to match(//)
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/9.99/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/4/)
    expect(rendered).to match(/false/)
  end
end
