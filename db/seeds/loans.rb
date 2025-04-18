# Create sample loans
puts "Creating sample loans..."

# Get some users
users = User.where(status: :active).limit(10)

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

  # Create the loan
  loan = Loan.create!(
    user: user,
    wallet: user.wallet,
    loan_type: loan_type,
    amount: amount,
    interest_rate: interest_rate,
    term_days: term_days,
    due_date: due_date,
    status: status,
    purpose: [ "Business expansion", "Emergency medical expenses", "Education fees", "Home improvement", "Debt consolidation" ].sample,
    processing_fee: (amount * 0.02).round(2) # 2% processing fee
  )

  # Set timestamps based on status
  case status
  when :approved, :active, :completed, :defaulted
    loan.update(approved_at: rand(1..30).days.ago)
  end

  case status
  when :active, :completed, :defaulted
    loan.update(disbursed_at: loan.approved_at + rand(1..3).days)
  end

  case status
  when :completed
    loan.update(completed_at: loan.disbursed_at + rand(1..term_days).days)
  when :defaulted
    loan.update(defaulted_at: loan.due_date + rand(1..30).days)
  end

  # Create repayments for active and completed loans
  if [ :active, :completed ].include?(status)
    # For completed loans, create full repayment
    if status == :completed
      LoanRepayment.create!(
        loan: loan,
        amount: loan.amount_due,
        status: :successful,
        paid_at: loan.completed_at
      )
    else
      # For active loans, create partial repayments
      repayment_count = rand(1..3)
      repayment_amount = (loan.amount_due / (repayment_count + rand(1..2))).round(2)

      repayment_count.times do
        LoanRepayment.create!(
          loan: loan,
          amount: repayment_amount,
          status: :successful,
          paid_at: loan.disbursed_at + rand(1..term_days/2).days
        )
      end
    end
  end

  print "."
end

puts "\nCreated #{Loan.count} loans with #{LoanRepayment.count} repayments."
