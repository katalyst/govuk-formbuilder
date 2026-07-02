# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  # Makes govuk_formbuilder_init available to views (see README).
  helper Katalyst::GOVUK::FormBuilder::Frontend

  # Render all forms with the GOV.UK form builder (extended by this gem).
  default_form_builder GOVUKDesignSystemFormBuilder::FormBuilder
end
