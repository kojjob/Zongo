class AddTermsAcceptedAtToContactSubmissions < ActiveRecord::Migration[8.0]
  def change
    # Add terms_accepted_at column if it doesn't exist
    unless column_exists?(:contact_submissions, :terms_accepted_at)
      add_column :contact_submissions, :terms_accepted_at, :datetime
    end
  end
end
