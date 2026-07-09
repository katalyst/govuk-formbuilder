# frozen_string_literal: true

require "active_support/inflector"
require "govuk_design_system_formbuilder"
require "rails/engine"

module Katalyst
  module GOVUK
    module FormBuilder
      class Engine < ::Rails::Engine
        ActiveSupport::Inflector.inflections(:en) do |inflect|
          inflect.acronym "GOVUK"
        end

        config.paths.add("lib", autoload_once: true)

        initializer "katalyst-govuk-formbuilder.autoload", before: :setup_once_autoloader do
          Rails.autoloaders.once.ignore File.expand_path(root.join("lib/katalyst-govuk-formbuilder.rb"))
        end

        initializer "katalyst-govuk-formbuilder.assets" do
          config.after_initialize do |app|
            if app.config.respond_to?(:assets)
              app.config.assets.paths << root.join("node_modules")
              app.config.assets.precompile += %w(katalyst-govuk-formbuilder.js)
            end
          end
        end

        # Mix the extension modules into GOVUKDesignSystemFormBuilder once, after the main
        # autoloader is set up. The modules in app/helpers stay reloadable, but a consuming
        # app only needs them wired once: re-applying on every reload would accumulate stale
        # copies in the (non-reloadable) GOVUKDesignSystemFormBuilder ancestor chain.
        #
        # When developing this gem, spec/dummy re-applies them via to_prepare so that edits
        # to the extension modules are picked up on reload.
        initializer "katalyst-govuk-formbuilder.extensions" do
          config.after_initialize do
            FormBuilder.inject_extensions!
          end
        end

        initializer "katalyst-govuk-formbuilder.importmap", before: "importmap" do |app|
          if app.config.respond_to?(:importmap)
            app.config.importmap.paths << root.join("config/importmap.rb")
            app.config.importmap.cache_sweepers << root.join("app/assets/javascripts")
          end
        end
      end
    end
  end
end
