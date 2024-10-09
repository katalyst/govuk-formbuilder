# frozen_string_literal: true

require "govuk_design_system_formbuilder"

module Katalyst
  module GOVUK
    module Formbuilder
      module Elements
        class Combobox < GOVUKDesignSystemFormBuilder::Base
          include GOVUKDesignSystemFormBuilder::Traits::Error
          include GOVUKDesignSystemFormBuilder::Traits::Label
          include GOVUKDesignSystemFormBuilder::Traits::Hint
          include GOVUKDesignSystemFormBuilder::Traits::HTMLAttributes

          def initialize(builder, object_name, attribute_name, options_or_src, options:, form_group:, label:, hint:,
                         caption:, **kwargs, &block)
            super(builder, object_name, attribute_name)
            @block           = block

            @form_group      = form_group
            @hint            = hint
            @label           = label
            @caption         = caption
            @options_or_src  = options_or_src
            @options         = options
            @html_attributes = kwargs
          end

          def html
            GOVUKDesignSystemFormBuilder::Containers::FormGroup.new(*bound, **@form_group).html do
              safe_join([label_element, hint_element, error_element, combobox])
            end
          end

          private

          def combobox
            @builder.combobox(@attribute_name, @options_or_src, **@options, **attributes(@html_attributes), &@block)
          end

          def options
            {
              id:    field_id(link_errors: true),
              class: classes,
              aria:  { describedby: combine_references(hint_id, error_id) },
            }
          end

          def classes
            combine_references(%(#{brand}-combobox), error_class)
          end

          def error_class
            %(#{brand}-combobox--error) if has_errors?
          end
        end
      end
    end
  end
end
