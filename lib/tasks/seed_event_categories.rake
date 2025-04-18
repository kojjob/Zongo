namespace :db do
  namespace :seed do
    desc "Seed event categories"
    task event_categories: :environment do
      load Rails.root.join('db/seeds/event_categories.rb')
    end
  end
end
