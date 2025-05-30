source "https://rubygems.org"

gem "rails", "~> 8.0.2"
gem "haml", "~> 6.3"
gem "haml-rails", "~> 2.1"
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "jbuilder"
gem "devise", "~> 4.9"
gem "pagy", "~> 6.1"
gem "elasticsearch", "~> 9.0.3"
gem "redis", "~> 4.8"
gem "active_attr"
gem "searchkick", "~> 5.5", ">= 5.5.1"

# gem "bcrypt", "~> 3.1.7"

gem "tzinfo-data", platforms: %i[ windows jruby ]

gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

gem "kamal", require: false
gem "bootsnap", require: false
gem "thruster", require: false

# gem "image_processing", "~> 1.2"

group :development, :test do
  gem "bullet", "~> 8.0", ">= 8.0.5"
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "factory_bot_rails", "~> 6.4", ">= 6.4.4"
  gem "pry-rails"
  gem "brakeman", require: false

  gem "rubocop-rails-omakase", require: false
  gem "rspec-rails", "~> 6.1.0"
end

group :development do
  gem "annotaterb", "~> 4.13"
  gem "ffaker", "~> 2.24"
  gem "html2haml", "~> 2.2"
  gem "rubocop", "~> 1.75", ">= 1.75.3"
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "database_cleaner-active_record"
  gem "database_cleaner-redis"
  gem "selenium-webdriver"
end
