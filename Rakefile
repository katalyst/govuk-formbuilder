# frozen_string_literal: true

require "bundler/setup"
require "bundler/gem_tasks"

namespace "yarn" do
  desc "Install dependencies"
  task :install do
    sh <<~CMD
      yarn install
    CMD
  end
end

desc "Compile js/css with rollup"
task build: "yarn:install" do
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
