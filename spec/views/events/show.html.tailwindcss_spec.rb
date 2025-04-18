require 'rails_helper'

RSpec.describe "events/show", type: :view do
  before(:each) do
    assign(:event, create(:event,
      title: "Title",
      description: "MyText",
      short_description: "MyText",
      capacity: 2,
      status: 3,
      access_code: "Access Code",
      slug: "Slug"
    ))
  end

  it "renders attributes in <p>" do
    render
    # Just check for the key attributes we explicitly set
    expect(rendered).to match(/Title/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/Access Code/)
    expect(rendered).to match(/Slug/)
  end
end
