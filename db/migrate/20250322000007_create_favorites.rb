class CreateFavorites < ActiveRecord::Migration[7.0]
  def change
    # Skip creating this table as we're using event_favorites instead
    # In the future, consider migrating to this more flexible polymorphic structure

    # Commented out to prevent creating a duplicate favorites table:
    # create_table :favorites do |t|
    #   t.references :user, null: false, foreign_key: true
    #   t.references :favoritable, polymorphic: true, null: false
    #
    #   t.timestamps
    # end
    #
    # add_index :favorites, [:user_id, :favoritable_type, :favoritable_id], unique: true, name: 'index_favorites_on_user_and_favoritable'

    # For documentation purposes: The polymorphic favorites table would replace event_favorites
    # and provide more flexibility for favoriting different types of content.
  end
end
