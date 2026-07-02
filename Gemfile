# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem "rake"
gem "rubocop-katalyst", require: false

# Dummy app + functional specs
gem "importmap-rails"
gem "propshaft"
gem "puma"
gem "rails"
gem "rspec-rails"
gem "sqlite3"
gem "stimulus-rails"
gem "turbo-rails"

# Optional formbuilder integrations exercised by the dummy app
gem "hotwire_combobox"
gem "image_processing"

group :development, :test do
  gem "brakeman", require: false
end

group :test do
  gem "capybara", require: false
  gem "compare-xml"
  gem "cuprite"
  gem "factory_bot_rails"
  gem "faker"
  gem "nokogiri"
  gem "rails-controller-testing"
end

gemspec
