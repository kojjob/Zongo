require 'rails_helper'

RSpec.describe "ticket_types/new", type: :view do
  before(:each) do
    assign(:ticket_type, TicketType.new(
      event: nil,
      name: "MyString",
      description: "MyText",
      price: "9.99",
      quantity: 1,
      sold_count: 1,
      max_per_user: 1,
      transferable: false
    ))
  end

  it "renders new ticket_type form" do
    render

    assert_select "form[action=?][method=?]", ticket_types_path, "post" do

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
