require 'database_cleaner/active_record'
require 'database_cleaner/redis'

RSpec.configure do |config|
  config.before(:suite) do
    # Disable the remote database safeguard
    DatabaseCleaner.allow_remote_database_url = true

    # Clean all tables to start - only for ActiveRecord
    DatabaseCleaner[:active_record].clean_with(:truncation)

    # Configure DatabaseCleaner to use transaction strategy by default for ActiveRecord
    DatabaseCleaner[:active_record].strategy = :transaction

    # Use deletion strategy for Redis
    DatabaseCleaner[:redis].strategy = :deletion
    DatabaseCleaner[:redis].clean_with(:deletion)
  end

  # Start DatabaseCleaner before each test
  config.before(:each) do
    DatabaseCleaner.start
  end

  # Clean after each test
  config.after(:each) do
    DatabaseCleaner.clean
  end

  # For tests tagged with :js => true, use truncation strategy for ActiveRecord
  config.before(:each, js: true) do
    DatabaseCleaner[:active_record].strategy = :truncation
  end

  # Reset back to transaction strategy after JS tests for ActiveRecord
  config.after(:each, js: true) do
    DatabaseCleaner[:active_record].strategy = :transaction
  end
end
