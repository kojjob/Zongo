class CreateAgricultureTables < ActiveRecord::Migration[8.0]
  def change
    # Create regions table
    create_table :regions do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.text :description
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.timestamps
    end
    add_index :regions, :name, unique: true
    add_index :regions, :code, unique: true

    # Create crops table
    create_table :crops do |t|
      t.string :name, null: false
      t.text :description
      t.string :scientific_name
      t.string :growing_season
      t.integer :season_start # Month number (1-12)
      t.integer :season_end # Month number (1-12)
      t.integer :growing_time # Average days to maturity
      t.integer :category, default: 0
      t.integer :popularity, default: 0
      t.boolean :featured, default: false
      t.timestamps
    end
    add_index :crops, :name, unique: true
    add_index :crops, :category
    add_index :crops, :featured

    # Create crop_prices table
    create_table :crop_prices do |t|
      t.references :crop, null: false, foreign_key: true
      t.references :region, foreign_key: true
      t.decimal :price, precision: 10, scale: 2, null: false
      t.date :date, null: false
      t.string :unit, null: false, default: 'kg'
      t.string :market, null: false
      t.text :notes
      t.timestamps
    end
    add_index :crop_prices, [:crop_id, :date, :region_id, :market], name: 'index_crop_prices_on_crop_date_region_market'

    # Create weather_forecasts table
    create_table :weather_forecasts do |t|
      t.references :region, null: false, foreign_key: true
      t.date :forecast_date, null: false
      t.decimal :temperature_high, precision: 5, scale: 2, null: false
      t.decimal :temperature_low, precision: 5, scale: 2, null: false
      t.decimal :precipitation_chance, precision: 5, scale: 2, null: false
      t.decimal :precipitation_amount, precision: 5, scale: 2, null: false
      t.integer :weather_condition, default: 0
      t.decimal :wind_speed, precision: 5, scale: 2
      t.string :wind_direction
      t.decimal :humidity, precision: 5, scale: 2
      t.text :notes
      t.timestamps
    end
    add_index :weather_forecasts, [:region_id, :forecast_date], unique: true

    # Create crop_listings table
    create_table :crop_listings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :crop, null: false, foreign_key: true
      t.references :region, foreign_key: true
      t.string :title, null: false
      t.text :description, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.decimal :quantity, precision: 10, scale: 2, null: false
      t.string :unit, null: false, default: 'kg'
      t.integer :listing_type, default: 0
      t.integer :status, default: 0
      t.boolean :featured, default: false
      t.boolean :negotiable, default: true
      t.date :expiry_date
      t.datetime :sold_at
      t.string :location
      t.text :terms
      t.timestamps
    end
    add_index :crop_listings, :status
    add_index :crop_listings, :listing_type
    add_index :crop_listings, :featured

    # Create crop_listing_inquiries table
    create_table :crop_listing_inquiries do |t|
      t.references :user, null: false, foreign_key: true
      t.references :crop_listing, null: false, foreign_key: true
      t.text :message, null: false
      t.text :response
      t.integer :status, default: 0
      t.boolean :read, default: false
      t.decimal :quantity
      t.decimal :offered_price, precision: 10, scale: 2
      t.datetime :responded_at
      t.timestamps
    end
    add_index :crop_listing_inquiries, :status
    add_index :crop_listing_inquiries, :read

    # Create agriculture_resources table
    create_table :agriculture_resources do |t|
      t.string :title, null: false
      t.text :content, null: false
      t.references :crop, foreign_key: true
      t.references :user, foreign_key: true
      t.integer :resource_type, default: 0
      t.boolean :published, default: true
      t.boolean :featured, default: false
      t.datetime :published_at
      t.integer :view_count, default: 0
      t.string :external_url
      t.string :video_url
      t.string :tags
      t.timestamps
    end
    add_index :agriculture_resources, :published
    add_index :agriculture_resources, :featured
    add_index :agriculture_resources, :resource_type
  end
end
