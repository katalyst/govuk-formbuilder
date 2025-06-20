# frozen_string_literal: true

require "katalyst-govuk-formbuilder"

# Backwards compatibility for Koi 4
module Katalyst
  module GOVUK
    Formbuilder = FormBuilder
  end
end
