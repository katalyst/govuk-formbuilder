# frozen_string_literal: true

require "govuk_design_system_formbuilder"

module Katalyst
  module GOVUK
    module Formbuilder
      module Traits
        # Extend GovukDesignSystemFormBuilder::Traits::Label set the default size to small for non-nested labels.
        module Label
          extend ActiveSupport::Concern

          included do
            private

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
      end
    end
  end
end
