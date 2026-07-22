# frozen_string_literal: true

Rails.application.routes.draw do
  resources :profiles

  # Guide pages that mirror the doc pages govuk_design_system_formbuilder ships
  # (https://govuk-form-builder.netlify.app). Each page catalogues the rendered
  # example forms for one component so we can click through and compare.
  get "guide/:page", to: "guide#show", as: :guide_page, constraints: { page: /[a-z_]+/ }

  # Every example renders in its own turbo frame, so each form is isolated to
  # its own request: a lazy GET to render it and a POST to round-trip it.
  match "guide/:page/:example", to: "examples#show", as: :example,
                                via: %i[get post],
                                constraints: { page: /[a-z_]+/, example: /[a-z_]+/ }

  # System tests point fields here to hold direct uploads until released.
  post "blocking_direct_uploads", to: "blocking_direct_uploads#create"

  root to: "guide#index"
end
