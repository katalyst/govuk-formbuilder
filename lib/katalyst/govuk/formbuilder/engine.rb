# frozen_string_literal: true

require "active_support/inflector"
require "govuk_design_system_formbuilder"
require "rails/engine"

module Katalyst
  module GOVUK
    module Formbuilder
      class Engine < ::Rails::Engine
        ActiveSupport::Inflector.inflections(:en) do |inflect|
          inflect.acronym "GOVUK"
        end

        config.eager_load_namespaces << Katalyst::GOVUK::Formbuilder
        config.paths.add("lib", autoload_once: true)

        initializer "katalyst-govuk-formbuilder.assets" do
          config.after_initialize do |app|
            if app.config.respond_to?(:assets)
              app.config.assets.paths << root.join("node_modules")
              app.config.assets.precompile += %w(katalyst-govuk-formbuilder.js)
            end
          end
        end

        initializer "katalyst-govuk-formbuilder.extensions" do
          GOVUKDesignSystemFormBuilder::Builder.include(Formbuilder::Extensions)
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
