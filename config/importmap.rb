# frozen_string_literal: true

pin "@katalyst/govuk-formbuilder", to: "katalyst/govuk/formbuilder.js"

pin_all_from Katalyst::GOVUK::FormBuilder::Engine.root.join("app/assets/javascripts"),
             # preload in tests so that we don't start clicking before controllers load
             preload: Rails.env.test?
