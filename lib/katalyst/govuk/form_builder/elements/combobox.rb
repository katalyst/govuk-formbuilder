# frozen_string_literal: true

require "govuk_design_system_formbuilder"

module Katalyst
  module GOVUK
    module FormBuilder
      module Elements
        class Combobox < GOVUKDesignSystemFormBuilder::Base
          include GOVUKDesignSystemFormBuilder::Traits::Error
          include GOVUKDesignSystemFormBuilder::Traits::Label
          include GOVUKDesignSystemFormBuilder::Traits::Hint
          include GOVUKDesignSystemFormBuilder::Traits::HTMLAttributes
          include GOVUKDesignSystemFormBuilder::Traits::ContentBeforeAndAfter

          def initialize(builder,
                         object_name,
                         attribute_name,
                         options_or_src,
                         options:,
                         form_group:,
                         label:,
                         hint:,
                         caption:,
                         before_input:,
                         after_input:,
                         **kwargs,
                         &block)
            # assign the block to a variable rather than passing to super so
            # we can send it through to #combobox
            super(builder, object_name, attribute_name)
            @block           = block

            @form_group      = form_group
            @hint            = hint
            @label           = label
            @caption         = caption
            @options_or_src  = options_or_src
            @options         = options
            @html_attributes = kwargs
            @before_input    = before_input
            @after_input     = after_input
          end

          def html
            GOVUKDesignSystemFormBuilder::Containers::FormGroup.new(*bound, **@form_group).html do
              safe_join([
                          label_element,
                          hint_element,
                          error_element,
                          before_input_content,
                          combobox,
                          after_input_content,
                        ])
            end
          end

          private

          def combobox
            attrs         = attributes(@html_attributes)
            attrs[:class] = attrs.delete(:class).join(" ") # hotwire_combobox does not support flattening classes
            @builder.combobox(@attribute_name, @options_or_src, **@options, **attrs, &@block)
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
