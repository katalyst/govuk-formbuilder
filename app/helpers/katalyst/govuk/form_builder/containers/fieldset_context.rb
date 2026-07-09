# frozen_string_literal: true

module Katalyst
  module GOVUK
    module FormBuilder
      module Containers
        module FieldsetContext
          def initialize(builder, object_name = nil, attribute_name = nil, &)
            builder.fieldset_context << attribute_name

            super

            builder.fieldset_context.pop
          end
        end
      end
    end
  end
end
