module Katalyst
  module GOVUK
    module Formbuilder
      # Engine is responsible for adding assets to load path
      class Engine < ::Rails::Engine
        PRECOMPILE_ASSETS = %w( katalyst/govuk/formbuilder.css )

        initializer "katalyst-govuk-formbuilder.assets" do
          if Rails.application.config.respond_to?(:assets)
            Rails.application.config.assets.precompile += PRECOMPILE_ASSETS
          end
        end
      end
    end
  end
end
