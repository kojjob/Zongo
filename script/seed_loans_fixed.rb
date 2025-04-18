# This script can be run from the Rails console with:
# load Rails.root.join('script', 'seed_loans_fixed.rb')

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
  microloan: { min: 50, max: 500, term_days: 30 },
  emergency: { min: 100, max: 1000, term_days: 14 },
  installment: { min: 500, max: 5000, term_days: 90 },
  business: { min: 1000, max: 10000, term_days: 180 },
  agricultural: { min: 500, max: 5000, term_days: 120 },
  salary_advance: { min: 200, max: 2000, term_days: 30 }
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

  # Set term days based on loan type
  term_days = amount_range[:term_days]

  # Set due date based on term days
  due_date = Date.today + term_days.days

  # Randomly select status based on probabilities
  status = statuses.max_by { |_, weight| rand ** (1.0 / weight) }.first

  # Calculate processing fee
  processing_fee = (amount * 0.02).round(2) # 2% processing fee

  # Create the loan
  loan = Loan.new(
    user: user,
    wallet: user.wallet,
    reference_number: "LOAN-#{SecureRandom.alphanumeric(8).upcase}",
    loan_type: loan_type,
    amount: amount,
    interest_rate: interest_rate,
    term_days: term_days,
    due_date: due_date,
    status: status,
    purpose: [ "Business expansion", "Emergency medical expenses", "Education fees", "Home improvement", "Debt consolidation" ].sample,
    processing_fee: processing_fee
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
    loan.update_columns(completed_at: loan.disbursed_at + rand(1..term_days/2).days)
  when :defaulted
    loan.update_columns(defaulted_at: loan.due_date + rand(1..30).days)
  end

  # Calculate amount due (principal + interest)
  interest_amount = (amount * interest_rate / 100) * (term_days / 365.0)
  amount_due = amount + interest_amount + processing_fee

  # Update amount_due
  loan.update_columns(amount_due: amount_due)

  # Create repayments for active and completed loans
  if [ :active, :completed ].include?(status)
    # For completed loans, create full repayment
    if status == :completed
      LoanRepayment.create!(
        loan: loan,
        amount: amount_due,
        principal_amount: amount,
        interest_amount: interest_amount,
        status: :successful,
        paid_at: loan.completed_at
      )
    else
      # For active loans, create partial repayments
      repayment_count = rand(1..3)
      repayment_amount = (amount_due / (repayment_count + rand(1..2))).round(2)

      repayment_count.times do
        principal_portion = (repayment_amount * (amount / amount_due)).round(2)
        interest_portion = repayment_amount - principal_portion

        LoanRepayment.create!(
          loan: loan,
          amount: repayment_amount,
          principal_amount: principal_portion,
          interest_amount: interest_portion,
          status: :successful,
          paid_at: loan.disbursed_at + rand(1..term_days/2).days
        )
      end
    end
  end

  print "."
end

puts "\nCreated #{Loan.count} loans with #{LoanRepayment.count} repayments."
