# frozen_string_literal: true

require "active_support/configurable"

module Katalyst
  module GOVUK
    module FormBuilder
      module Config
        extend ActiveSupport::Concern

        included do
          config_accessor(:document_mime_types) do
            %w[image/png image/gif image/jpeg image/webp application/pdf audio/*].freeze
          end

          config_accessor(:image_mime_types) do
            %w[image/png image/gif image/jpeg image/webp].freeze
          end
        end
      end
    end
  end
end
