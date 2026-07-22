# frozen_string_literal: true

module Katalyst
  module GOVUK
    module FormBuilder
      module Elements
        class Attachment < GOVUKDesignSystemFormBuilder::Elements::File
          include FormBuilder::Traits::Attachment

          def initialize(builder, object_name, attribute_name, direct_upload_url:, **, &)
            super(builder, object_name, attribute_name, javascript: true, **, &)

            @direct_upload_url = direct_upload_url

            raise ArgumentError, "Unsupported attribute type #{value.class} for #{attribute_name}" unless attachment?
          end

          def options
            super.merge(
              "data-direct-upload-url" => @direct_upload_url,
              multiple: many?,
            )
          end

          private

          def file
            safe_join([attachment, @builder.file_field(@attribute_name, attributes(@html_attributes))])
          end

          def file_with_javascript_markup
            tag.div(class: "#{brand}-file-upload-wrapper", data: { controller: "#{brand}-file-upload" }, **i18n_data) { file }
          end
        end
      end
    end
  end
end
