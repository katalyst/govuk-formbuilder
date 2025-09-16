# frozen_string_literal: true

require "govuk_design_system_formbuilder"

module Katalyst
  module GOVUK
    module FormBuilder
      module Elements
        class Time < GOVUKDesignSystemFormBuilder::Base
          include GOVUKDesignSystemFormBuilder::Traits::Input
          include GOVUKDesignSystemFormBuilder::Traits::Error
          include GOVUKDesignSystemFormBuilder::Traits::Hint
          include GOVUKDesignSystemFormBuilder::Traits::Label
          include GOVUKDesignSystemFormBuilder::Traits::Supplemental
          include GOVUKDesignSystemFormBuilder::Traits::HTMLAttributes

          private

          def builder_method
            :time_field
          end
        end
      end
    end
  end
end
