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
        end
      end
    end
  end
end
