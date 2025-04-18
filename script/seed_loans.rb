# This script can be run from the Rails console with:
# load Rails.root.join('script', 'seed_loans.rb')

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

# Loan types and their typical amounts
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

  # Calculate amount due (principal + interest)
  amount_due = amount + (amount * interest_rate / 100 * term_months / 12.0)
  processing_fee = (amount * 0.02).round(2) # 2% processing fee

  # Create the loan
  loan = Loan.new(
    user: user,
    reference_number: "LOAN-#{SecureRandom.alphanumeric(8).upcase}",
    loan_type: loan_type,
    amount: amount,
    interest_rate: interest_rate,
    term_months: term_months,
    due_date: due_date,
    status: status,
    purpose: [ "Business expansion", "Emergency medical expenses", "Education fees", "Home improvement", "Debt consolidation" ].sample,
    credit_score: user.credit_scores.first&.score || rand(300..850),
    current_balance: amount_due + processing_fee
  )

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

  # Create repayments for active and completed loans
  if [ :active, :completed ].include?(status)
    # For completed loans, create full repayment
    if status == :completed
      LoanRepayment.create!(
        loan: loan,
        amount: loan.current_balance,
        status: :successful,
        paid_at: loan.completed_at
      )
    else
      # For active loans, create partial repayments
      repayment_count = rand(1..3)
      repayment_amount = (loan.current_balance / (repayment_count + rand(1..2))).round(2)

      repayment_count.times do
        LoanRepayment.create!(
          loan: loan,
          amount: repayment_amount,
          status: :successful,
          paid_at: loan.disbursed_at + rand(1..30).days
        )
      end
    end
  end

  print "."
end

puts "\nCreated #{Loan.count} loans with #{LoanRepayment.count} repayments."
