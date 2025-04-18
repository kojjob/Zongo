# This script can be run from the Rails console with:
# load Rails.root.join('script', 'fix_existing_loans.rb')

puts "Fixing existing loans..."

# Check if term_days column exists
if Loan.column_names.include?('term_days')
  # Update all loans to set term_days based on term_months
  Loan.find_each do |loan|
    if loan.term_months.present? && (loan.term_days.nil? || loan.term_days == 0)
      # Convert months to days (approximate)
      days = loan.term_months * 30
      loan.update_column(:term_days, days)
      print "."
    end
  end

  puts "\nFixed #{Loan.count} loans."
else
  puts "The term_days column doesn't exist in the loans table. Run the migration first."
end
