# frozen_string_literal: true

require "active_support"
require "active_support/rails"

module Katalyst
  module GOVUK
    module FormBuilder
      # Mix our extension modules into the GOVUKDesignSystemFormBuilder classes.
      #
      # This is called from an after_initialize block (see Engine) or to_prepare in development (see dummy app)
      def inject_extensions!
        GOVUKDesignSystemFormBuilder.include(Config)
        GOVUKDesignSystemFormBuilder::Builder.include(Builder)
        GOVUKDesignSystemFormBuilder::Elements::Label.include(Elements::Label)
        GOVUKDesignSystemFormBuilder::Elements::Legend.include(Elements::Legend)
        GOVUKDesignSystemFormBuilder::Traits::Label.include(Traits::Label)
        GOVUKDesignSystemFormBuilder::Containers::Fieldset.include(Containers::FieldsetContext)
        GOVUKDesignSystemFormBuilder::Containers::CheckBoxesFieldset.include(Containers::FieldsetContext)
        GOVUKDesignSystemFormBuilder::Containers::RadioButtonsFieldset.include(Containers::FieldsetContext)
      end
      module_function :inject_extensions!
    end
  end
end

require "katalyst/govuk/form_builder/engine"
