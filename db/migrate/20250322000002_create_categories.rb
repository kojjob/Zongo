class CreateCategories < ActiveRecord::Migration[7.0]
  def change
    # Skip creating a new categories table since we're using event_categories

    # Add new fields to event_categories
    unless column_exists?(:event_categories, :color_code)
      add_column :event_categories, :color_code, :string
    end

    unless column_exists?(:event_categories, :display_order)
      add_column :event_categories, :display_order, :integer, default: 0
    end

    # Add not null constraint to name if needed (commented for safety)
    # change_column_null :event_categories, :name, false
  end
end
