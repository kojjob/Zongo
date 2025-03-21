# Setup Instructions

To complete the setup of the new features, please follow these steps:

## 1. Run Migrations
Run the following commands in your terminal:

```bash
bundle install
bin/rails db:migrate
```

## 2. Install any required gems
The statement generation feature might require additional gems for PDF generation. Consider adding:

```ruby
# Add to your Gemfile if PDF generation is needed
gem 'wicked_pdf'
gem 'wkhtmltopdf-binary'
```

Then run `bundle install` again.

## 3. Restart your application
```bash
bin/rails server
```

## 4. New Features Available
The following new features are now available:

- **Scheduled Transactions**: Create recurring transactions with flexible scheduling options
- **Statement Generation**: Generate and export account statements as PDFs

## 5. Navigation
You can access the new features through:
- The Transactions dropdown menu in the navbar
- "Recurring" for scheduled transactions
- "Reports" for statement generation

## Note About Migrations
If you encounter any issues with migrations, please check that:
1. You don't have conflicting migration timestamps
2. You only have one migration trying to create each table
