# frozen_string_literal: true

require "active_support"

module Katalyst
  module GOVUK
    module Formbuilder
      extend ActiveSupport::Autoload
    end
  end
end

require "katalyst/govuk/formbuilder/engine"
