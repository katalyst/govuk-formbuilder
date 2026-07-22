# frozen_string_literal: true

require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("dummy/config/environment", __dir__)

# Prevent database truncation if the environment is running in production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "factory_bot_rails"

# Load supporting ruby files (matchers, capybara config, factories, ...)
Dir[File.expand_path("support/**/*.rb", __dir__)].each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # Lets system tests attach fixtures with `file_fixture_upload("avatar.png")`.
  config.file_fixture_path = File.expand_path("fixtures/files", __dir__)

  config.define_derived_metadata(file_path: %r{spec/builders}) do |metadata|
    metadata[:type] ||= :helper
  end

  # Remove active-storage uploads
  config.after(:suite) do
    FileUtils.rm_rf(Rails.application.root.join("tmp", "storage"))
  end
end
