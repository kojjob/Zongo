class AddTermDaysToLoans < ActiveRecord::Migration[8.0]
  def change
    # Add term_days column if it doesn't exist
    unless column_exists?(:loans, :term_days)
      add_column :loans, :term_days, :integer

      # Convert term_months to term_days for existing records
      Loan.find_each do |loan|
        if loan.term_months.present?
          # Convert months to days (approximate)
          days = loan.term_months * 30
          loan.update_column(:term_days, days)
        end
      end
    end
  end
end
