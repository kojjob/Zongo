# This script can be run from the Rails console with:
# load Rails.root.join('script', 'seed_loans_compatible.rb')

# Get some users
users = User.where(status: :active).limit(10)
if users.empty?
  puts "No active users found. Creating a sample user..."
  user = User.create!(
    email: "testuser@example.com",
    password: "password123",
    password_confirmation: "password123",
    first_name: "Test",
    last_name: "User",
    phone: "+233123456789",
    status: :active,
    kyc_level: :verified,
    confirmed_at: Time.current
  )

  # Create wallet for the user if it doesn't exist
  unless user.wallet
    Wallet.create!(
      user: user,
      wallet_id: "WALLET-#{SecureRandom.alphanumeric(8).upcase}",
      status: :active,
      balance: rand(1000..5000),
      currency: "GHS",
      daily_limit: 5000
    )
  end

  users = [ user ]
end

# Create credit scores for users
puts "Creating credit scores..."
users.each do |user|
  # Create a credit score if the user doesn't have one
  unless user.credit_scores.exists?
    score = rand(300..850)
    factors = {
      payment_history: rand(1..100),
      credit_utilization: rand(1..100),
      credit_age: rand(1..100),
      account_mix: rand(1..100),
      recent_inquiries: rand(1..100)
    }

    CreditScore.create!(
      user: user,
      score: score,
      factors: factors.to_json,
      is_current: true,
      calculated_at: Time.current
    )

    print "."
  end
end

puts "\nCreated #{CreditScore.count} credit scores."

# Loan types and their typical amounts and terms
loan_types = {
  microloan: { min: 50, max: 500, term_months: 1 },
  emergency: { min: 100, max: 1000, term_months: 1 },
  installment: { min: 500, max: 5000, term_months: 3 },
  business: { min: 1000, max: 10000, term_months: 6 },
  agricultural: { min: 500, max: 5000, term_months: 4 },
  salary_advance: { min: 200, max: 2000, term_months: 1 }
}

# Statuses with their probabilities
statuses = {
  pending: 0.2,
  approved: 0.1,
  active: 0.4,
  completed: 0.2,
  defaulted: 0.05,
  rejected: 0.05
}

puts "Creating sample loans..."

# Create 50 sample loans
50.times do
  user = users.sample
  loan_type = loan_types.keys.sample
  amount_range = loan_types[loan_type]

  # Generate random amount within range
  amount = rand(amount_range[:min]..amount_range[:max])

  # Generate random interest rate between 5% and 25%
  interest_rate = rand(5.0..25.0).round(2)

  # Set term months based on loan type
  term_months = amount_range[:term_months]

  # Set due date based on term months
  due_date = Date.today + term_months.months

  # Randomly select status based on probabilities
  status = statuses.max_by { |_, weight| rand ** (1.0 / weight) }.first

  # Calculate processing fee
  processing_fee = (amount * 0.02).round(2) # 2% processing fee

  # Create the loan with attributes that match the schema
  loan_attributes = {
    user: user,
    reference_number: "LOAN-#{SecureRandom.alphanumeric(8).upcase}",
    loan_type: loan_type,
    amount: amount,
    interest_rate: interest_rate,
    due_date: due_date,
    status: status,
    purpose: [ "Business expansion", "Emergency medical expenses", "Education fees", "Home improvement", "Debt consolidation" ].sample,
    processing_fee: processing_fee
  }

  # Add term_months or term_days based on what's available in the schema
  if Loan.column_names.include?('term_months')
    loan_attributes[:term_months] = term_months
  end

  if Loan.column_names.include?('term_days')
    loan_attributes[:term_days] = term_months * 30
  end

  # Create the loan
  loan = Loan.new(loan_attributes)

  # Skip validation to handle any schema differences
  loan.save(validate: false)

  # Set timestamps based on status
  case status
  when :approved, :active, :completed, :defaulted
    loan.update_columns(approved_at: rand(1..30).days.ago)
  end

  case status
  when :active, :completed, :defaulted
    loan.update_columns(disbursed_at: loan.approved_at + rand(1..3).days)
  end

  case status
  when :completed
    loan.update_columns(completed_at: loan.disbursed_at + rand(1..term_months.months.to_i / 2).days)
  when :defaulted
    loan.update_columns(defaulted_at: loan.due_date + rand(1..30).days)
  end

  # Calculate amount due (principal + interest)
  days = term_months * 30
  interest_amount = (amount * interest_rate / 100) * (days / 365.0)
  amount_due = amount + interest_amount + processing_fee

  # Update amount_due if the column exists
  if Loan.column_names.include?('amount_due')
    loan.update_columns(amount_due: amount_due)
  end

  # Update current_balance if the column exists
  if Loan.column_names.include?('current_balance')
    loan.update_columns(current_balance: amount_due)
  end

  # Create repayments for active and completed loans
  if [ :active, :completed ].include?(status)
    # For completed loans, create full repayment
    if status == :completed
      repayment_attributes = {
        loan: loan,
        amount: amount_due,
        status: :successful,
        paid_at: loan.completed_at
      }

      # Add principal_amount and interest_amount if the columns exist
      if LoanRepayment.column_names.include?('principal_amount')
        repayment_attributes[:principal_amount] = amount
      end

      if LoanRepayment.column_names.include?('interest_amount')
        repayment_attributes[:interest_amount] = interest_amount
      end

      LoanRepayment.create!(repayment_attributes)
    else
      # For active loans, create partial repayments
      repayment_count = rand(1..3)
      repayment_amount = (amount_due / (repayment_count + rand(1..2))).round(2)

      repayment_count.times do
        principal_portion = (repayment_amount * (amount / amount_due)).round(2)
        interest_portion = repayment_amount - principal_portion

        repayment_attributes = {
          loan: loan,
          amount: repayment_amount,
          status: :successful,
          paid_at: loan.disbursed_at + rand(1..term_months.months.to_i * 15).days
        }

        # Add principal_amount and interest_amount if the columns exist
        if LoanRepayment.column_names.include?('principal_amount')
          repayment_attributes[:principal_amount] = principal_portion
        end

        if LoanRepayment.column_names.include?('interest_amount')
          repayment_attributes[:interest_amount] = interest_portion
        end

        LoanRepayment.create!(repayment_attributes)
      end
    end
  end

  print "."
end

puts "\nCreated #{Loan.count} loans with #{LoanRepayment.count} repayments."
