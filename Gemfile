source "https://rubygems.org"

ruby "~> 3.2"

gem "rails", "~> 8.1.1"
gem "propshaft"
gem "pg", "~> 1.5"
gem "puma", ">= 6.0"
gem "redis", "~> 5.0"
gem "sidekiq", "~> 7.2"

gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"

gem "devise", "~> 4.9"
gem "pundit", "~> 2.3"

gem "kubeclient", "~> 4.11"
gem "faraday", "~> 2.9"

gem "jbuilder"
gem "bootsnap", require: false

gem "tzinfo-data", platforms: %i[windows jruby]

gem "kamal", require: false
gem "thruster", require: false

gem "image_processing", "~> 1.2"

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "rspec-rails", "~> 8.0"
  gem "factory_bot_rails"
  gem "faker"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
end

group :development do
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "shoulda-matchers"
  gem "vcr"
  gem "webmock"
  gem "simplecov", require: false
end
