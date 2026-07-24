# frozen_string_literal: true

require "govuk_design_system_formbuilder"

module Katalyst
  module GOVUK
    module FormBuilder
      module Traits
        # Generates attachment inputs and previews for ActiveStorage associations.
        module Attachment
          extend ActiveSupport::Concern

          include ActionView::Helpers::NumberHelper

          def attachment?
            value.is_a?(ActiveStorage::Attached)
          end

          def one?
            value.is_a?(ActiveStorage::Attached::One)
          end

          def many?
            value.is_a?(ActiveStorage::Attached::Many)
          end

          def value
            @builder.object.send(@attribute_name)
          end

          delegate :attached?, to: :value

          # @return [ActiveSupport::SafeBuffer,nil]
          def attachment
            return unless attached?

            # Preserve unsaved multi-part form uploads before rendering
            # mimics direct-upload for non-js consumers.
            persist_pending_blobs

            blobs = (one? ? [value.blob] : value.blobs).select(&:persisted?)
            safe_join(blobs.map { |blob| attachment_for(blob) })
          end

          # @param [ActiveStorage::Blob] blob
          # @return [ActiveSupport::SafeBuffer,nil]
          def attachment_for(blob)
            tag.figure(class: "#{brand}-attachment",
                       aria:  { labelledby: attachment_id_for(blob, :caption) },
                       data:  { controller: "#{brand}-attachment" }) do
              safe_join([
                          attachment_preview_for(blob),
                          attachment_caption_for(blob),
                          attachment_actions_for(blob),
                        ])
            end
          end

          # A <div> with form elements for managing the attachment.
          # @param [ActiveStorage::Blob] blob
          # @return [ActiveSupport::SafeBuffer|nil]
          def attachment_actions_for(blob)
            return if blob.nil?

            tag.div(class: "actions") do
              safe_join([
                          attachment_input_for(blob),
                          attachment_remove_for(blob),
                        ])
            end
          end

          # A <select> with options to keep or remove the attachment that can be used without JavaScript.
          # @param [ActiveStorage::Blob] blob
          # @return [ActiveSupport::SafeBuffer,nil]
          def attachment_input_for(blob)
            @builder.select(
              @attribute_name,
              [[blob.filename.to_s, blob.signed_id],
               ["Remove #{blob.filename}", ""]],
              { selected: blob.signed_id },
              id:   attachment_id_for(blob, :input),
              name: @builder.field_name(@attribute_name, multiple: many?),
              aria: { labelledby: attachment_id_for(blob, :caption) },
            )
          end

          # A <button> that will remove the attachment when clicked (requires javascript).
          # @param [ActiveStorage::Blob] blob
          # @return [ActiveSupport::SafeBuffer,nil]
          def attachment_remove_for(blob)
            tag.button("&times;".html_safe,
                       type: "button",
                       aria: { label: "Remove #{blob.filename}" },
                       data: { action: "#{brand}-attachment#destroy" })
          end

          # The representation is rendered lazily: the variant is processed
          # when the browser requests it, never during the form render. If the
          # blob's bytes turn out to be missing or unprocessable the preview
          # simply fails to load — validating attachment content is the
          # model's responsibility, not the form's.
          # @param [ActiveStorage::Blob] blob
          # @return [ActiveSupport::SafeBuffer,nil]
          def attachment_preview_for(blob)
            return unless blob.representable?

            url = @builder.attachment_preview_url(blob.representation(resize_and_pad: [100, 100, { crop: :centre }]))
            return if url.nil?

            # Setting alt to "" as the details already describe the attachment, equivalent to role="presentation"
            @builder.image_tag(url, alt: "")
          end

          # The caption is a polite atomic live region: JS writes upload status
          # into the status span, and the announcement reads the whole caption
          # so the user hears which file the status belongs to.
          # @param [ActiveStorage::Blob] blob
          # @return [ActiveSupport::SafeBuffer,nil]
          def attachment_caption_for(blob)
            tag.figcaption(id: attachment_id_for(blob, :caption), aria: { atomic: true, live: "polite" }) do
              safe_join([
                          tag.span(blob.filename, class: "filename"),
                          " ",
                          tag.span(number_to_human_size(blob.byte_size), class: "size"),
                          " ",
                          tag.span(class: "status"),
                        ])
            end
          end

          # @param [ActiveStorage::Blob] blob
          # @return [String,nil]
          def attachment_id_for(blob, *suffixes)
            return nil if @html_attributes.fetch(:skip_default_ids, false)

            @builder.field_id(@attribute_name, :attachment, blob.id, *suffixes)
          end

          private

          def persist_pending_blobs
            case (change = @builder.object.attachment_changes[@attribute_name.to_s])
            when ActiveStorage::Attached::Changes::CreateOne
              persist_pending_change(change)
            when ActiveStorage::Attached::Changes::CreateMany
              change.pending_uploads.each do |subchange|
                persist_pending_change(subchange)
              end
            end
          end

          def persist_pending_change(change)
            change.upload
            change.blob.save!
          rescue ActiveStorage::Error => e
            # no recovery available
            log_dropped_upload(e)
          end

          def log_dropped_upload(error)
            Rails.logger.warn(
              "Dropped pending attachment for " \
              "#{@builder.object.class}##{@attribute_name}: #{error.class}: #{error.message}",
            )
          end
        end
      end
    end
  end
end
