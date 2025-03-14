# frozen_string_literal: true

require "bundler/setup"
require "bundler/gem_tasks"

require "rubocop/katalyst/rake_task"
RuboCop::Katalyst::RakeTask.new

require "rubocop/katalyst/prettier_task"
RuboCop::Katalyst::PrettierTask.new

desc "Stub environment so tasks that assume Rails can run"
task :environment do
  # no-op
end

namespace "yarn" do
  desc "Install dependencies"
  task :install do
    sh <<~CMD
      yarn install
    CMD
  end

  desc "Apply patches after install"
  task :patch do
    sh <<~CMD
      for patch in patches/*; do
        patch --strip=0 --forward --reject-file=- --input ${patch} || true
      done
    CMD
  end
end

desc "Compile js/css with rollup"
task build: %w[yarn:install yarn:patch lint] do
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

task default: :build
