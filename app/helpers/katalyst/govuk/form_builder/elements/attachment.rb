# frozen_string_literal: true

module Katalyst
  module GOVUK
    module FormBuilder
      module Elements
        class Attachment < GOVUKDesignSystemFormBuilder::Elements::File
          include FormBuilder::Traits::Attachment

          def initialize(builder, object_name, attribute_name, direct_upload_url:,
                         upload_succeeded_text: nil, upload_failed_text: nil,
                         retry_button_text: nil, file_removed_text: nil,
                         remove_button_text: nil, remove_button_content_text: nil, **, &)
            super(builder, object_name, attribute_name, javascript: true, **, &)

            @direct_upload_url          = direct_upload_url
            @upload_succeeded_text      = upload_succeeded_text
            @upload_failed_text         = upload_failed_text
            @retry_button_text          = retry_button_text
            @file_removed_text          = file_removed_text
            @remove_button_text         = remove_button_text
            @remove_button_content_text = remove_button_content_text

            raise ArgumentError, "Unsupported attribute type #{value.class} for #{attribute_name}" unless attachment?
          end

          def options
            super.merge(
              "data-direct-upload-url" => @direct_upload_url,
              include_hidden: false, # we always render remove_field
              multiple: many?,
            )
          end

          private

          # Extends the file element's data-i18n.* attributes with the
          # attachment strings: an explicit option wins, else the current
          # locale's translation. When neither adds anything beyond the
          # gem's en defaults the attribute is omitted and the JS falls
          # back to its bundled mirror of the same table.
          def i18n_data
            super.merge({
              "data-i18n.upload-succeeded"      => attachment_text(@upload_succeeded_text, :upload_succeeded),
              "data-i18n.upload-failed"         => attachment_text(@upload_failed_text, :upload_failed),
              "data-i18n.retry-button"          => attachment_text(@retry_button_text, :retry_button),
              "data-i18n.file-removed"          => attachment_text(@file_removed_text, :file_removed),
              "data-i18n.remove-button"         => attachment_text(@remove_button_text, :remove_button),
              "data-i18n.remove-button-content" => attachment_text(@remove_button_content_text, :remove_button_content),
            }.compact)
          end

          def attachment_text(option, key)
            return option if option

            text = attachment_translation(key)
            text unless text == Traits::Attachment::BUNDLED_DEFAULTS[key.to_s]
          end

          def file
            safe_join([remove_field, attachment, @builder.file_field(@attribute_name, attributes(@html_attributes))])
          end

          def file_with_javascript_markup
            tag.div(class: "#{brand}-file-upload-wrapper", data: { controller: "govuk-file-upload" }, **i18n_data) do
              file
            end
          end

          # A removed figure takes its select with it and an empty file input contributes
          # no value. This input ensures that there's always a value to process so that
          # attachments can be removed (both one? and many? cases).
          def remove_field
            tag.input(name: @builder.field_name(@attribute_name, multiple: many?), type: "hidden", value: "")
          end
        end
      end
    end
  end
end
