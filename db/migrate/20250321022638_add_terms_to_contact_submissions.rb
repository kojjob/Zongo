class AddTermsToContactSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :contact_submissions, :terms, :boolean, default: false
  end
end
