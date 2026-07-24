# frozen_string_literal: true

module Katalyst
  module GOVUK
    module FormBuilder
      module Config
        extend ActiveSupport::Concern

        included do
          def document_mime_types
            config.document_mime_types
          end

          def document_mime_types=(value)
            config.document_mime_types = value
          end

          config.document_mime_types = %w[image/png image/gif image/jpeg image/webp application/pdf audio/*].freeze

          def image_mime_types
            config.image_mime_types
          end

          def image_mime_types=(value)
            config.image_mime_types = value
          end

          config.image_mime_types = %w[image/png image/gif image/jpeg image/webp].freeze

          def attachment_preview_representation
            config.attachment_preview_representation
          end

          def attachment_preview_representation=(value)
            config.attachment_preview_representation = value
          end

          config.attachment_preview_representation = { resize_and_pad: [100, 100, { crop: :centre }] }.freeze

          def use_legacy_file_fields?
            config.use_legacy_file_fields
          end

          def use_legacy_file_fields=(value)
            config.use_legacy_file_fields = value
          end

          config.use_legacy_file_fields = false
        end
      end
    end
  end
end
