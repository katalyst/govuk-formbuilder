# frozen_string_literal: true

Rails.application.routes.draw do
  resources :profiles

  root to: "profiles#index"
end
