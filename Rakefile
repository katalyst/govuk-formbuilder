# frozen_string_literal: true

require "bundler/setup"
require "bundler/gem_tasks"
require "rspec/core/rake_task"

APP_RAKEFILE = File.expand_path("spec/dummy/Rakefile", __dir__)
load "rails/tasks/engine.rake"

# prepend app:spec:prepare to run migrations against the dummy app before specs
RSpec::Core::RakeTask.new(spec: %w[app:spec:prepare])

require "rubocop/katalyst/rake_task"
RuboCop::Katalyst::RakeTask.new

require "rubocop/katalyst/prettier_task"
RuboCop::Katalyst::PrettierTask.new

namespace "yarn" do
  desc "Install dependencies"
  task :install do
    sh <<~CMD
      yarn install
    CMD
  end
end

desc "Compile js/css with rollup"
task build: %w[yarn:install] do
  sh <<~CMD
    yarn build && yarn build_css
  CMD
end

desc "Remove generated js/css files"
task clobber: "yarn:install" do
  exec <<~CMD
    yarn clean
  CMD
end

desc "Run security checks"
task security: :environment do
  sh "bundle exec brakeman -q -w2 spec/dummy"
end

desc "Run the full CI suite (style, assets, specs, security) via bin/ci"
task :ci do
  sh "bin/ci"
end

task default: :ci
