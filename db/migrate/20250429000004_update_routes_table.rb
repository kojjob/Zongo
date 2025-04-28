class UpdateRoutesTable < ActiveRecord::Migration[8.0]
  def change
    # Add columns if they don't exist
    unless column_exists?(:routes, :transport_company_id)
      add_reference :routes, :transport_company, foreign_key: true
    end

    unless column_exists?(:routes, :duration_minutes)
      add_column :routes, :duration_minutes, :integer
    end

    unless column_exists?(:routes, :base_price)
      add_column :routes, :base_price, :decimal, precision: 10, scale: 2
    end

    unless column_exists?(:routes, :currency)
      add_column :routes, :currency, :string, default: "GHS"
    end

    unless column_exists?(:routes, :popular)
      add_column :routes, :popular, :boolean, default: false
    end

    unless column_exists?(:routes, :active)
      add_column :routes, :active, :boolean, default: true
    end

    unless column_exists?(:routes, :schedule)
      add_column :routes, :schedule, :json
    end

    unless column_exists?(:routes, :amenities)
      add_column :routes, :amenities, :json
    end

    unless column_exists?(:routes, :metadata)
      add_column :routes, :metadata, :json
    end

    # Add indexes if they don't exist
    unless index_exists?(:routes, :popular)
      add_index :routes, :popular
    end

    unless index_exists?(:routes, :active)
      add_index :routes, :active
    end

    # Handle transport_type column conversion if it exists and is a string
    if column_exists?(:routes, :transport_type) && !column_exists?(:routes, :transport_type_string)
      # Check column type
      if column_for_attribute(:routes, :transport_type).type == :string
        # Change string transport_type to integer transport_type with enum
        rename_column :routes, :transport_type, :transport_type_string
        add_column :routes, :transport_type, :integer, default: 0

        # Add data migration to convert transport_type_string to transport_type integer
        reversible do |dir|
          dir.up do
            execute <<-SQL
              UPDATE routes
              SET transport_type = CASE
                WHEN transport_type_string = 'bus' THEN 0
                WHEN transport_type_string = 'train' THEN 1
                WHEN transport_type_string = 'ferry' THEN 2
                WHEN transport_type_string = 'plane' THEN 3
                ELSE 0
              END
            SQL
          end
        end

        unless index_exists?(:routes, :transport_type)
          add_index :routes, :transport_type
        end
      end
    elsif !column_exists?(:routes, :transport_type)
      # Add transport_type column if it doesn't exist
      add_column :routes, :transport_type, :integer, default: 0

      unless index_exists?(:routes, :transport_type)
        add_index :routes, :transport_type
      end
    end
  end

  private

  def column_for_attribute(table, column_name)
    connection.columns(table).find { |c| c.name == column_name.to_s }
  end
end
