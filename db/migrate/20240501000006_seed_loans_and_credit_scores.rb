class SeedLoansAndCreditScores < ActiveRecord::Migration[8.0]
  def up
    # Only proceed if the tables exist
    return unless table_exists?(:loans) && table_exists?(:credit_scores)

    # Get some users
    users = User.where(status: :active).limit(10)
    if users.empty?
      puts "No active users found. Skipping loan and credit score seeding."
      return
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
      end
    end

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
      interest_amount = amount * interest_rate / 100 * term_months / 12.0
      processing_fee = (amount * 0.02).round(2) # 2% processing fee
      total_amount = amount + interest_amount + processing_fee

      # Create loan attributes based on available columns
      loan_attributes = {
        user: user,
        reference_number: "LOAN-#{SecureRandom.alphanumeric(8).upcase}",
        loan_type: loan_type,
        amount: amount,
        interest_rate: interest_rate,
        term_months: term_months,
        due_date: due_date,
        status: status,
        purpose: [ "Business expansion", "Emergency medical expenses", "Education fees", "Home improvement", "Debt consolidation" ].sample,
        credit_score: user.credit_scores.first&.score || rand(300..850)
      }

      # Add optional attributes if the columns exist
      if Loan.column_names.include?("current_balance")
        loan_attributes[:current_balance] = total_amount
      end

      if Loan.column_names.include?("amount_due")
        loan_attributes[:amount_due] = total_amount
      end

      if Loan.column_names.include?("processing_fee")
        loan_attributes[:processing_fee] = processing_fee
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

      # Create repayments for active and completed loans
      if [ :active, :completed ].include?(status)
        # Use the total amount for repayments

        # For completed loans, create full repayment
        if status == :completed
          repayment_attributes = {
            loan: loan,
            amount: total_amount,
            status: :successful,
            paid_at: loan.completed_at
          }

          # Use payment_transaction instead of transaction to avoid conflicts

          # Add principal and interest amounts if columns exist
          if LoanRepayment.column_names.include?("principal_amount")
            repayment_attributes[:principal_amount] = amount
          end

          if LoanRepayment.column_names.include?("interest_amount")
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
              paid_at: loan.disbursed_at + rand(1..30).days
            }

            # Use payment_transaction instead of transaction to avoid conflicts

            # Add principal and interest amounts if columns exist
            if LoanRepayment.column_names.include?("principal_amount")
              repayment_attributes[:principal_amount] = principal_portion
            end

            if LoanRepayment.column_names.include?("interest_amount")
              repayment_attributes[:interest_amount] = interest_portion
            end

            LoanRepayment.create!(repayment_attributes)
          end
        end
      end
    end
  end

  def down
    # This migration is not reversible
  end
end
