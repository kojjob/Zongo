require 'rails_helper'

RSpec.describe "ticket_types/edit", type: :view do
  let(:event) { create(:event) }
  let(:ticket_type) {
    TicketType.create!(
      event: event,
      name: "MyString",
      description: "MyText",
      price: "9.99",
      quantity: 1,
      sold_count: 1,
      max_per_user: 1,
      transferable: false
    )
  }

  before(:each) do
    assign(:ticket_type, ticket_type)
  end

  it "renders the edit ticket_type form" do
    render

    assert_select "form[action=?][method=?]", ticket_type_path(ticket_type), "post" do
      assert_select "input[name=?]", "ticket_type[event_id]"

      assert_select "input[name=?]", "ticket_type[name]"

      assert_select "textarea[name=?]", "ticket_type[description]"

      assert_select "input[name=?]", "ticket_type[price]"

      assert_select "input[name=?]", "ticket_type[quantity]"

      assert_select "input[name=?]", "ticket_type[sold_count]"

      assert_select "input[name=?]", "ticket_type[max_per_user]"

      assert_select "input[name=?]", "ticket_type[transferable]"
    end
  end
end
