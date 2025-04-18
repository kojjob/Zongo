namespace :db do
  namespace :seed do
    desc "Seed loans and credit scores data"
    task loans: :environment do
      load Rails.root.join("db", "seeds", "loans_and_credit_scores.rb")
    end
  end
end
