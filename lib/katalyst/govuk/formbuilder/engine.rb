module Katalyst
  module GOVUK
    module Formbuilder
      # Engine is responsible for adding assets to load path
      class Engine < ::Rails::Engine
        PRECOMPILE_ASSETS = %w(
          katalyst/govuk/formbuilder.js
          katalyst/govuk/formbuilder.min.js
          katalyst/govuk/formbuilder.min.css
          katalyst/govuk/formbuilder.css
        )

        initializer "katalyst-govuk-formbuilder.assets" do
          config.after_initialize do |app|
            if app.config.respond_to?(:assets)
              app.config.assets.precompile += PRECOMPILE_ASSETS
            end
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
