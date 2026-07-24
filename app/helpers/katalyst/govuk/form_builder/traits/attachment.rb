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

          # The attachment strings' canonical home (config/locales).
          I18N_SCOPE = %i[katalyst govuk attachment].freeze

          # The gem's own en strings, read straight from its locale file:
          # resolving them through I18n would absorb a host app's en
          # overrides, and this table is the baseline those overrides are
          # detected against.
          BUNDLED_DEFAULTS = YAML.load_file(
            Engine.root.join("config/locales/en.yml"),
          ).dig("en", *I18N_SCOPE.map(&:to_s)).freeze

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
                       data:  { controller: "govuk-attachment" }) do
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
               [remove_button_label(blob), ""]],
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
            tag.button(remove_button_content,
                       type: "button",
                       aria: { label: remove_button_label(blob) },
                       data: { action: "govuk-attachment#destroy" })
          end

          # The remove strings render here and in the JS figure template, so
          # both draw from the same options (or matching defaults) — the two
          # figure sources must stay string-identical.
          # @param [ActiveStorage::Blob] blob
          # @return [String]
          def remove_button_label(blob)
            if @remove_button_text
              # %{filename} is the option placeholder (govuk-frontend's i18n
              # convention), substituted directly — not a Ruby format token.
              # rubocop:disable Style/FormatStringToken
              @remove_button_text.gsub("%{filename}", blob.filename.to_s)
              # rubocop:enable Style/FormatStringToken
            else
              attachment_translation(:remove_button, filename: blob.filename.to_s)
            end
          end

          # @return [String]
          def remove_button_content
            @remove_button_content_text || attachment_translation(:remove_button_content)
          end

          # The current locale's translation, falling back to the gem's en
          # defaults rather than a "translation missing" marker.
          # @return [String]
          def attachment_translation(key, **)
            I18n.t(key, scope: I18N_SCOPE, default: nil, **) ||
              I18n.t(key, scope: I18N_SCOPE, locale: :en, **)
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

            url = @builder.attachment_preview_url(
              blob.representation(config.attachment_preview_representation),
            )
            return if url.nil?

            # Setting alt to "" as the details already describe the attachment, equivalent to role="presentation"
            @builder.image_tag(url, alt: "", class: "preview")
          end

          # The caption is a polite atomic live region: JS writes upload status
          # into the status span, and the announcement reads the whole caption
          # so the user hears which file the status belongs to.
          # @param [ActiveStorage::Blob] blob
          # @return [ActiveSupport::SafeBuffer,nil]
          def attachment_caption_for(blob)
            tag.figcaption(id:    attachment_id_for(blob, :caption),
                           class: "caption",
                           aria:  { atomic: true, live: "polite" }) do
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
