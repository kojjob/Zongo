class AddReadToContactSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :contact_submissions, :read, :boolean, default: false
    add_column :contact_submissions, :read_at, :datetime
  end
end
