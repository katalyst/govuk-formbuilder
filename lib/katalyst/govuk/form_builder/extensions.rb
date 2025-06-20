# frozen_string_literal: true

require "govuk_design_system_formbuilder"

module Katalyst
  module GOVUK
    module FormBuilder
      module Extensions
        extend ActiveSupport::Concern

        included do
          GOVUKDesignSystemFormBuilder.include(Config)
          GOVUKDesignSystemFormBuilder::Builder.include(Builder)
          GOVUKDesignSystemFormBuilder::Elements::Label.include(Elements::Label)
          GOVUKDesignSystemFormBuilder::Elements::Legend.include(Elements::Legend)
          GOVUKDesignSystemFormBuilder::Traits::Label.include(Traits::Label)
          GOVUKDesignSystemFormBuilder::Containers::Fieldset.include(Containers::FieldsetContext)
          GOVUKDesignSystemFormBuilder::Containers::CheckBoxesFieldset.include(Containers::FieldsetContext)
          GOVUKDesignSystemFormBuilder::Containers::RadioButtonsFieldset.include(Containers::FieldsetContext)
        end
      end
    end
  end
end
