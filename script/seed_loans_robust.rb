# This script can be run from the Rails console with:
# load Rails.root.join('script', 'seed_loans_robust.rb')

# Helper method to check if a model has a column
def model_has_column?(model, column_name)
  model.column_names.include?(column_name.to_s)
end

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
  term_days = term_months * 30

  # Set due date based on term
  due_date = Date.today + term_months.months

  # Randomly select status based on probabilities
  status = statuses.max_by { |_, weight| rand ** (1.0 / weight) }.first

  # Calculate processing fee
  processing_fee = (amount * 0.02).round(2) # 2% processing fee

  # Calculate amount due (principal + interest)
  interest_amount = (amount * interest_rate / 100) * (term_days / 365.0)
  total_amount = amount + interest_amount + processing_fee

  # Create loan attributes based on available columns
  loan_attributes = {
    user: user,
    reference_number: "LOAN-#{SecureRandom.alphanumeric(8).upcase}",
    loan_type: loan_type,
    amount: amount,
    interest_rate: interest_rate,
    due_date: due_date,
    status: status,
    purpose: [ "Business expansion", "Emergency medical expenses", "Education fees", "Home improvement", "Debt consolidation" ].sample
  }

  # Add wallet if the association exists
  if user.respond_to?(:wallet) && user.wallet
    loan_attributes[:wallet] = user.wallet
  end

  # Add credit score if the column exists
  if model_has_column?(Loan, :credit_score) && user.credit_scores.exists?
    loan_attributes[:credit_score] = user.credit_scores.first.score
  end

  # Add term_months if the column exists
  if model_has_column?(Loan, :term_months)
    loan_attributes[:term_months] = term_months
  end

  # Add term_days if the column exists
  if model_has_column?(Loan, :term_days)
    loan_attributes[:term_days] = term_days
  end

  # Add processing_fee if the column exists
  if model_has_column?(Loan, :processing_fee)
    loan_attributes[:processing_fee] = processing_fee
  end

  # Add amount_due if the column exists
  if model_has_column?(Loan, :amount_due)
    loan_attributes[:amount_due] = total_amount
  end

  # Add current_balance if the column exists
  if model_has_column?(Loan, :current_balance)
    loan_attributes[:current_balance] = total_amount
  end

  # Create the loan
  begin
    loan = Loan.new(loan_attributes)
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

    # Create repayments for active and completed loans
    if [ :active, :completed ].include?(status)
      # For completed loans, create full repayment
      if status == :completed
        repayment_attributes = {
          loan: loan,
          amount: total_amount,
          status: :successful,
          paid_at: loan.completed_at
        }

        # Add payment_transaction if we have a Transaction model
        if defined?(Transaction) && rand(10) < 5 # 50% chance to have a transaction for completed loans
          # Create a transaction for this repayment
          transaction = Transaction.create!(
            transaction_id: "TXN-#{SecureRandom.alphanumeric(8).upcase}",
            transaction_type: :loan_repayment,
            status: :completed,
            amount: amount_due,
            currency: "GHS",
            description: "Final loan repayment for #{loan.reference_number}",
            completed_at: repayment_attributes[:paid_at]
          ) rescue nil

          repayment_attributes[:payment_transaction] = transaction if transaction
        end

        # Add principal and interest amounts if columns exist
        if model_has_column?(LoanRepayment, :principal_amount)
          repayment_attributes[:principal_amount] = amount
        end

        if model_has_column?(LoanRepayment, :interest_amount)
          repayment_attributes[:interest_amount] = interest_amount
        end

        LoanRepayment.create!(repayment_attributes)
      else
        # For active loans, create partial repayments
        repayment_count = rand(1..3)
        repayment_amount = (total_amount / (repayment_count + rand(1..2))).round(2)

        repayment_count.times do
          # Calculate principal and interest portions
          principal_portion = (repayment_amount * (amount / total_amount)).round(2)
          interest_portion = repayment_amount - principal_portion

          repayment_attributes = {
            loan: loan,
            amount: repayment_amount,
            status: :successful,
            paid_at: loan.disbursed_at + rand(1..term_days/2).days
          }

          # Add payment_transaction if we have a Transaction model
          if defined?(Transaction) && rand(10) < 3 # 30% chance to have a transaction
            # Create a transaction for this repayment
            transaction = Transaction.create!(
              transaction_id: "TXN-#{SecureRandom.alphanumeric(8).upcase}",
              transaction_type: :loan_repayment,
              status: :completed,
              amount: repayment_amount,
              currency: "GHS",
              description: "Loan repayment for #{loan.reference_number}",
              completed_at: repayment_attributes[:paid_at]
            ) rescue nil

            repayment_attributes[:payment_transaction] = transaction if transaction
          end

          # Add principal and interest amounts if columns exist
          if model_has_column?(LoanRepayment, :principal_amount)
            repayment_attributes[:principal_amount] = principal_portion
          end

          if model_has_column?(LoanRepayment, :interest_amount)
            repayment_attributes[:interest_amount] = interest_portion
          end

          LoanRepayment.create!(repayment_attributes)
        end
      end
    end

    print "."
  rescue => e
    puts "\nError creating loan: #{e.message}"
  end
end

puts "\nCreated #{Loan.count} loans with #{LoanRepayment.count} repayments."
