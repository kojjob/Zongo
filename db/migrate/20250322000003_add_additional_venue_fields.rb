class AddAdditionalVenueFields < ActiveRecord::Migration[7.0]
  def change
    # Add new fields to the existing venues table
    add_column :venues, :website, :string
    add_column :venues, :phone, :string
    add_column :venues, :state, :string

    # Add index on name if it doesn't exist
    unless index_exists?(:venues, :name)
      add_index :venues, :name
    end
  end
end
