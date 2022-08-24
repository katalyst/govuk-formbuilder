require "bundler/gem_tasks"

namespace :css do
  desc "Install dependencies"
  task :install do
    sh <<~CMD
      yarn install
    CMD
  end

  task compile: :install do
    sh <<~CMD
      yarn exec sass -- app/assets/stylesheets:lib/assets/stylesheets --load-path=node_modules
    CMD
  end

  desc "Remove generated CSS"
  task :clobber do
    exec <<~CMD
      find lib/assets -type f | xargs rm -f
    CMD
  end
end

# Default entry point
desc "Generate CSS"
task css: "css:compile"

# Add CSS dependencies to existing Rake tasks
task build: :css
task clobber: "css:clobber"

task default: :css
