# frozen_string_literal: true

require "govuk_design_system_formbuilder"

module Katalyst
  module GOVUK
    module FormBuilder
      module Elements
        # Extend Elements::Label to add support for human_attribute_name as a fallback
        module Label
          extend ActiveSupport::Concern

          included do
            def retrieve_text(option_text, hidden)
              text = option_text.presence ||
                localised_text(:label).presence ||
                human_attribute_name.presence ||
                @attribute_name.to_s.humanize.capitalize.presence

              if hidden
                tag.span(text, class: %(#{brand}-visually-hidden))
              else
                text
              end
            end
          end

          def human_attribute_name
            return unless @object_name.present? && @attribute_name.present?
            return unless @builder.object&.class.respond_to?(:human_attribute_name)

            @builder.object.class.human_attribute_name(@attribute_name)
          end
        end
      end
    end
  end
end
