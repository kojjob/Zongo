# Pagination Setup for Zongo App

This application uses the Pagy gem for pagination. To install all required gems:

```bash
# Run this command in your terminal from the project root
bundle install
```

## Why Pagy?

- Lightweight and performant - much faster than alternatives
- Customizable with Tailwind CSS support
- Easy to implement with minimal code changes

## Important Changes

1. Added the Pagy gem to the Gemfile
2. Created a Pagy initializer with Tailwind CSS support
3. Added Pagy pagination to transactions page
4. Created fallback mechanisms if the gem isn't available

After installing the gem, restart your Rails server to ensure all changes take effect:

```bash
# Restart your Rails server
bin/rails server
```

If you have any issues, please check the Rails logs for detailed error messages.
