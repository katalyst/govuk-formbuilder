# frozen_string_literal: true

require "govuk_design_system_formbuilder"

module Katalyst
  module GOVUK
    module FormBuilder
      module Elements
        class RichTextArea < GOVUKDesignSystemFormBuilder::Base
          using GOVUKDesignSystemFormBuilder::PrefixableArray

          include GOVUKDesignSystemFormBuilder::Traits::Error
          include GOVUKDesignSystemFormBuilder::Traits::Hint
          include GOVUKDesignSystemFormBuilder::Traits::Label
          include GOVUKDesignSystemFormBuilder::Traits::Supplemental
          include GOVUKDesignSystemFormBuilder::Traits::HTMLAttributes
          include GOVUKDesignSystemFormBuilder::Traits::HTMLClasses

          def initialize(builder, object_name, attribute_name, hint:, label:, caption:, form_group:, **kwargs, &)
            super(builder, object_name, attribute_name, &)

            @label           = label
            @caption         = caption
            @hint            = hint
            @form_group      = form_group
            @html_attributes = kwargs
          end

          def html
            GOVUKDesignSystemFormBuilder::Containers::FormGroup.new(*bound, **@form_group).html do
              safe_join([label_element, supplemental_content, hint_element, error_element, rich_text_area])
            end
          end

          private

          def rich_text_area
            @builder.rich_text_area(@attribute_name, **attributes(@html_attributes))
          end

          def classes
            build_classes(%(richtextarea), %(richtextarea--error) => has_errors?).prefix(brand)
          end

          def options
            {
              id:    field_id(link_errors: true),
              class: classes,
              aria:  { describedby: combine_references(hint_id, error_id, supplemental_id) },
            }
          end
        end
      end
    end
  end
end
