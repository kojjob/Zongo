class CreateComments < ActiveRecord::Migration[7.0]
  def change
    # Skip creating this table as we're using event_comments instead
    # The following is commented out to prevent creating a duplicate table

    # create_table :comments do |t|
    #   t.references :user, null: false, foreign_key: true
    #   t.references :event, null: false, foreign_key: true
    #   t.text :content, null: false
    #   t.boolean :is_approved, default: true
    #   t.references :parent, foreign_key: { to_table: :comments }, null: true
    #
    #   t.timestamps
    # end

    # Add is_approved field to event_comments if it doesn't exist
    unless column_exists?(:event_comments, :is_approved)
      add_column :event_comments, :is_approved, :boolean, default: true
    end
  end
end
