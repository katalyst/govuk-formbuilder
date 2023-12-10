# frozen_string_literal: true

require "govuk_design_system_formbuilder"

module Katalyst
  module GOVUK
    module Formbuilder
      module Extensions
        module Fieldset
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

module GOVUKDesignSystemFormBuilder
  module Builder
    # Keep track of whether we are inside a fieldset
    # This allows labels to default to bold ("s") normally but use the default otherwise
    def fieldset_context
      @fieldset_context ||= []
    end
  end

  module Traits
    module Label
      def label_content
        default = @builder.fieldset_context.count.positive? ? {} : { size: "s" }

        case @label
        when Hash
          default.merge(@label)
        when Proc
          default.merge(content: @label)
        else
          fail(ArgumentError, %(label must be a Proc or Hash))
        end
      end
    end
  end

  module Containers
    class Fieldset
      include Katalyst::GOVUK::Formbuilder::Extensions::Fieldset
    end

    class CheckBoxesFieldset
      include Katalyst::GOVUK::Formbuilder::Extensions::Fieldset
    end

    class RadioButtonsFieldset
      include Katalyst::GOVUK::Formbuilder::Extensions::Fieldset
    end
  end
end
