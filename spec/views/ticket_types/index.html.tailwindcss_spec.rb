require 'rails_helper'

RSpec.describe "ticket_types/index", type: :view do
  before(:each) do
    assign(:ticket_types, [
      TicketType.create!(
        event: nil,
        name: "Name",
        description: "MyText",
        price: "9.99",
        quantity: 2,
        sold_count: 3,
        max_per_user: 4,
        transferable: false
      ),
      TicketType.create!(
        event: nil,
        name: "Name",
        description: "MyText",
        price: "9.99",
        quantity: 2,
        sold_count: 3,
        max_per_user: 4,
        transferable: false
      )
    ])
  end

  it "renders a list of ticket_types" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("9.99".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(4.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(false.to_s), count: 2
  end
end
