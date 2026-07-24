# frozen_string_literal: true

module Katalyst
  module GOVUK
    module FormBuilder
      module Builder
        extend ActiveSupport::Concern

        included do
          # Delegate image_tag for attachment previews
          delegate :image_tag, to: :@template

          # Overwrite GOVUK default to set small to true
          # @see GOVUKDesignSystemFormBuilder::Builder#govuk_collection_radio_buttons
          def govuk_collection_radio_buttons(attribute_name, collection, value_method, text_method = nil,
                                             hint_method = nil, hint: {}, legend: {}, caption: {}, inline: false,
                                             small: true, bold_labels: nil,
                                             include_hidden: config.default_collection_radio_buttons_include_hidden,
                                             form_group: {}, **, &)
            GOVUKDesignSystemFormBuilder::Elements::Radios::Collection.new(
              self,
              object_name,
              attribute_name,
              collection,
              value_method:,
              text_method:,
              hint_method:,
              hint:,
              legend:,
              caption:,
              inline:,
              small:,
              bold_labels:,
              form_group:,
              include_hidden:,
              **,
              &
            ).html
          end

          # Overwrite GOVUK default to set small to true
          # @see GOVUKDesignSystemFormBuilder::Builder#govuk_radio_buttons_fieldset
          def govuk_radio_buttons_fieldset(attribute_name, hint: {}, legend: {}, caption: {}, inline: false,
                                           small: true, form_group: {}, **, &)
            GOVUKDesignSystemFormBuilder::Containers::RadioButtonsFieldset.new(
              self, object_name, attribute_name,
              hint:, legend:, caption:, inline:, small:, form_group:,
              **, &
            ).html
          end

          # Overwrite GOVUK default to set small to true
          # @see GOVUKDesignSystemFormBuilder::Builder#govuk_collection_check_boxes
          def govuk_collection_check_boxes(attribute_name, collection, value_method, text_method, hint_method = nil,
                                           hint: {}, legend: {}, caption: {}, small: true, form_group: {},
                                           include_hidden: config.default_collection_check_boxes_include_hidden,
                                           **, &)
            GOVUKDesignSystemFormBuilder::Elements::CheckBoxes::Collection.new(
              self,
              object_name,
              attribute_name,
              collection,
              value_method:,
              text_method:,
              hint_method:,
              hint:,
              legend:,
              caption:,
              small:,
              form_group:,
              include_hidden:,
              **,
              &
            ).html
          end

          # Overwrite GOVUK default to set small to true
          # @see GOVUKDesignSystemFormBuilder::Builder#govuk_check_boxes_fieldset
          def govuk_check_boxes_fieldset(attribute_name, legend: {}, caption: {}, hint: {}, small: true, form_group: {},
                                         multiple: true, **, &)
            GOVUKDesignSystemFormBuilder::Containers::CheckBoxesFieldset.new(
              self,
              object_name,
              attribute_name,
              hint:,
              legend:,
              caption:,
              small:,
              form_group:,
              multiple:,
              **,
              &
            ).html
          end
        end

        # Generates a check box within a fieldset to be used as a boolean toggle for a single attribute.
        # The values are 1 (toggled on), and 0 (toggled off).
        #
        # @param attribute_name [Symbol] The name of the attribute
        # @param small [Boolean] controls whether small check boxes are used instead of regular-sized ones
        # @param hint [Hash,Proc] The content of the hint. No hint will be added if 'text' is left +nil+. When a +Proc+
        #                         is supplied the hint will be wrapped in a +div+ instead of a +span+
        # @option hint text [String] the hint text
        # @option hint kwargs [Hash] additional arguments are applied as attributes to the hint
        # @param link_errors [Boolean] controls whether this checkbox should be linked to from {#govuk_error_summary}
        # @option label text [String] the label text
        # @option label size [String] the size of the label font, can be +xl+, +l+, +m+, +s+ or nil
        # @option label tag [Symbol,String] the label's wrapper tag, intended to allow labels to act as page headings
        # @option label hidden [Boolean] control the visibility of the label. Hidden labels will be read by
        #                                screenreaders
        # @option label kwargs [Hash] additional arguments are applied as attributes on the +label+ element
        # @option kwargs [Hash] kwargs additional arguments are applied as attributes to the +input+ element
        # @param block [Block] any HTML passed in will form the contents of the fieldset
        # @return [ActiveSupport::SafeBuffer] HTML output
        #
        # @example A single check box for terms and conditions
        #   = f.govuk_check_box_field :terms_agreed,
        #     link_errors: true,
        #     label: { text: 'Do you agree with our terms and conditions?' },
        #     hint: { text: 'You will not be able to proceed unless you do' }
        #
        def govuk_check_box_field(attribute_name, value = 1, unchecked_value = 0,
                                  small: true, hint: {}, label: {}, link_errors: false, **, &)
          govuk_check_boxes_fieldset(attribute_name, legend: nil, multiple: false, small:) do
            fieldset_context.pop # undo push from fieldset extension, labels should be bold unless already nested
            checkbox = govuk_check_box(attribute_name, value, unchecked_value,
                                       hint:,
                                       label:,
                                       link_errors:,
                                       multiple:    false,
                                       exclusive:   false,
                                       **, &)
            fieldset_context.push attribute_name # restore push from fieldset
            checkbox
          end
        end

        # Generates a select for an enum defined in the model.
        # @see GOVUKDesignSystemFormBuilder::Builder#govuk_collection_select
        def govuk_enum_select(attribute_name, **, &)
          govuk_collection_select(attribute_name, enum_values(attribute_name),
                                  :itself, enum_labels_for(attribute_name), **, &)
        end

        # Generates a checkbox fieldset for an enum defined in the model.
        #
        # @api internal
        # @see GOVUKDesignSystemFormBuilder::Builder#govuk_collection_check_boxes
        def govuk_enum_check_boxes(attribute_name, **, &)
          govuk_collection_check_boxes(attribute_name, enum_values(attribute_name),
                                       :itself, enum_labels_for(attribute_name), **, &)
        end

        # Generates a radio buttons fieldset for an enum defined in the model.
        # @see GOVUKDesignSystemFormBuilder::Builder#govuk_collection_radio_buttons
        def govuk_enum_radio_buttons(attribute_name, **, &)
          govuk_collection_radio_buttons(attribute_name, enum_values(attribute_name),
                                         :itself, enum_labels_for(attribute_name), **, &)
        end

        # Generates a pair of +trix-toolbar+ and +trix-editor+ elements with a label, optional hint.
        # Requires action-text to be correctly setup in the application
        #
        # @param attribute_name [Symbol] The name of the attribute
        # @param hint [Hash,Proc] The content of the hint. No hint will be added if 'text' is left +nil+. When a +Proc+
        #                         is supplied the hint will be wrapped in a +div+ instead of a +span+
        # @option hint text [String] the hint text
        # @option hint kwargs [Hash] additional arguments are applied as attributes to the hint
        # @param label [Hash,Proc] configures or sets the associated label content
        # @option label text [String] the label text
        # @option label size [String] the size of the label font, can be +xl+, +l+, +m+, +s+ or nil
        # @option label tag [Symbol,String] the label's wrapper tag, intended to allow labels to act as page headings
        # @option label hidden [Boolean] control the visibility of the label. Hidden labels will still be read by screen
        #   readers
        # @option label kwargs [Hash] additional arguments are applied as attributes on the +label+ element
        # @param caption [Hash] configures or sets the caption content which is inserted above the label
        # @option caption text [String] the caption text
        # @option caption size [String] the size of the caption, can be +xl+, +l+ or +m+. Defaults to +m+
        # @option caption kwargs [Hash] additional arguments are applied as attributes on the caption +span+ element
        # @option kwargs [Hash] kwargs additional arguments are applied as attributes to the +trix-editor+ element.
        #                       This is picked up and handled by the action-text gem
        # @param form_group [Hash] configures the form group
        # @option form_group classes [Array,String] sets the form group's classes
        # @option form_group kwargs [Hash] additional attributes added to the form group
        # @param & [Block] arbitrary HTML that will be rendered between the hint and the input
        # @return [ActiveSupport::SafeBuffer] HTML output
        #
        # @example A rich text area with injected content
        #   = f.govuk_rich_text_area :description,
        #     label: { text: 'Where did the incident take place?' } do
        #
        #     p.govuk-inset-text
        #       | If you don't know exactly leave this section blank
        #
        # @example A rich text area with the label supplied as a proc
        #   = f.govuk_rich_text_area :instructions,
        #     label: -> { tag.h3("How do you set it up?") }
        #
        def govuk_rich_textarea(attribute_name, hint: {}, label: {}, caption: {}, form_group: {}, **, &)
          Elements::RichTextarea.new(
            self, object_name, attribute_name,
            hint:, label:, caption:, form_group:, **, &
          ).html
        end
        alias_method :govuk_rich_text_area, :govuk_rich_textarea

        # Generates a +combobox+ element that uses Hotwire Combobox to generate a combobox selection element.
        # @see https://hotwirecombobox.com
        # @see https://github.com/josefarias/hotwire_combobox
        #
        # @param attribute_name [Symbol] The name of the attribute
        # @param options_or_src [Array] The +option+ values or a source path for async combobox
        # @param options [Hash] Options hash passed through to the +combobox+ helper
        # @param hint [Hash,Proc] The content of the hint. No hint will be added if 'text' is left +nil+.
        #   When a +Proc+ is supplied the hint will be wrapped in a +div+ instead of a +span+
        # @option hint text [String] the hint text
        # @option hint kwargs [Hash] additional arguments are applied as attributes to the hint
        # @param label [Hash,Proc] configures or sets the associated label content
        # @option label text [String] the label text
        # @option label size [String] the size of the label font, can be +xl+, +l+, +m+, +s+ or nil
        # @option label tag [Symbol,String] the label's wrapper tag, intended to allow labels to act as page headings
        # @option label hidden [Boolean] control the visibility of the label.
        #   Hidden labels will still be read by screenreaders
        # @option label kwargs [Hash] additional arguments are applied as attributes on the +label+ element
        # @param form_group [Hash] configures the form group
        # @option form_group kwargs [Hash] additional attributes added to the form group
        # @param before_input [String,Proc] the content injected before the input. No content will be added if +nil+
        # @param after_input [String,Proc] the content injected after the input. No content will be added if +nil+
        # @param & [Block] build the contents of the select element manually for exact control
        # @see https://hotwirecombobox.com Hotwire Combobox's +combobox+ (called by govuk_combobox)
        # @return [ActiveSupport::SafeBuffer] HTML output
        #
        # @example A combobox that allows the user to choose from a list of states
        #
        #   = f.combobox "state", State.all
        #
        # @example A combobox that allows the user to choose from an asynchronous states endpoint
        #
        #   = f.combobox "state", states_path
        #
        # @example A multi-select combobox that allows the user to choose multiple states
        #
        #   = f.combobox "state", State.all, multiselect_chip_src: states_chips_path
        #
        def govuk_combobox(attribute_name, options_or_src = [], options: {}, label: {}, hint: {}, form_group: {},
                           caption: {}, before_input: nil, after_input: nil, **, &)
          Elements::Combobox.new(
            self, object_name, attribute_name, options_or_src,
            options:, label:, hint:, form_group:, caption:, before_input:, after_input:, **, &
          ).html
        end

        # Generates an input of type +file+ with active storage and preview support.
        #
        # @param attribute_name [Symbol] The name of the attribute
        # @option label text [String] the label text
        # @option label tag [Symbol,String] the label's wrapper tag, intended to allow labels to act as page headings
        # @option label size [String] the size of the label font, can be +xl+, +l+, +m+, +s+ or nil
        # @option label hidden [Boolean] control the visability of the label. Hidden labels will stil be read by
        #   screenreaders
        # @option label kwargs [Hash] additional arguments are applied as attributes on the +label+ element
        # @param caption [Hash] configures or sets the caption content which is inserted above the label
        # @option caption text [String] the caption text
        # @option caption size [String] the size of the caption, can be +xl+, +l+ or +m+. Defaults to +m+
        # @option caption kwargs [Hash] additional arguments are applied as attributes on the caption +span+ element
        # @param hint [Hash,Proc] The content of the hint. No hint will be added if 'text' is left +nil+. When a
        #   +Proc+ is supplied the hint will be wrapped in a +div+ instead of a +span+
        # @option hint text [String] the hint text
        # @option hint kwargs [Hash] additional arguments are applied as attributes to the hint
        # @option kwargs [Hash] kwargs additional arguments are applied as attributes to the +input+ element
        # @param form_group [Hash] configures the form group
        # @option form_group kwargs [Hash] additional attributes added to the form group
        # @param before_input [String,Proc] the content injected before the input. No content will be added if left
        #   +nil+
        # @param after_input [String,Proc] the content injected after the input. No content will be added if left
        #   +nil+
        # @param choose_files_button_text [String] The text of the button that opens the file picker. Default is
        #   "Choose file". If javascript is not provided, this option will be ignored.
        # @param drop_instruction_text [String] The text informing users they can drop files. Default is
        #   "or drop file". If javascript is not provided, this option will be ignored.
        # @param multiple_files_chosen_text [Hash] The text displayed when multiple files have been chosen by the
        #   user. The component will replace the %{count} placeholder with the number of files selected. This uses
        #   the govuk-frontend pluralisation rules. If javascript is not provided, this option will be ignored.
        # @param multiple_files_chosen_one_text [String] The text displayed when JavaScript is enabled and one file
        #   has been chosen by the user. The component will replace the %{count} placeholder with the number of files
        #   selected. This can also be set by passing a hash with key +one:+ to +multiple_files_chosen_text+.
        # @param multiple_files_chosen_other_text [String] The text displayed when JavaScript is enabled and multiple
        #   files have been chosen by the user. The component will replace the %{count} placeholder with the number of
        #   files selected. This can also be set by passing a hash with key +other:+ to +multiple_files_chosen_text+.
        # @param no_file_chosen_text [String] The text displayed when no file has been chosen by the user. Default is
        #   "No file chosen". If javascript is not provided, this option will be ignored.
        # @param entered_drop_zone_text [String] The text announced by assistive technology when user drags files and
        #   enters the drop zone. Default is "Entered drop zone". If javascript is not provided, this option will be
        #   ignored.
        # @param left_drop_zone_text [String] The text announced by assistive technology when user drags files and
        #   leaves the drop zone without dropping. Default is "Left drop zone". If javascript is not provided, this
        #   option will be ignored.
        # @param upload_succeeded_text [String] The status shown in a figure's caption when its direct upload
        #   completes. Default is "Uploaded successfully". If javascript is not provided, this option will be ignored.
        # @param upload_failed_text [String] The status shown in a figure's caption when its direct upload fails.
        #   Default is "Upload failed — try again". If javascript is not provided, this option will be ignored.
        # @param retry_button_text [String] The label of the retry control offered on a failed upload. Default is
        #   "Try again". If javascript is not provided, this option will be ignored.
        # @param file_removed_text [String] The text announced by assistive technology when a figure is removed. The
        #   component will replace the %{filename} placeholder with the removed file's name. Default is
        #   "%{filename} removed". If javascript is not provided, this option will be ignored.
        # @param remove_button_text [String] The accessible name of each figure's remove control and the text of its
        #   no-JavaScript remove option. The component will replace the %{filename} placeholder with the figure's
        #   file name. Default is "Remove %{filename}".
        # @param remove_button_content_text [String] The visible content of each figure's remove button. Default is
        #   "×".
        # @param & [Block] arbitrary HTML that will be rendered between the hint and the input
        #
        # @example A photo upload field with file type specifier and injected content
        #   = f.govuk_attachment_field :photo, label: { text: 'Upload your photo' }, accept: 'image/*' do
        #
        #     p.govuk-inset-text
        #       | Explicit images will result in account termination
        #
        # @example A CV upload field with label as a proc
        #   = f.govuk_attachment_field :cv, label: -> { tag.h3('Upload your CV') }
        #
        # @see https://design-system.service.gov.uk/components/file-upload/ GOV.UK file upload
        # @see https://design-system.service.gov.uk/styles/typography/#headings-with-captions Headings with captions
        # @see https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/file MDN documentation for file upload
        def govuk_attachment_field(
          attribute_name,
          label: {},
          caption: {},
          hint: {},
          form_group: {},
          before_input: nil,
          after_input: nil,
          choose_files_button_text: nil,
          drop_instruction_text: nil,
          multiple_files_chosen_text: nil,
          multiple_files_chosen_one_text: nil,
          multiple_files_chosen_other_text: nil,
          no_file_chosen_text: nil,
          entered_drop_zone_text: nil,
          left_drop_zone_text: nil,
          upload_succeeded_text: nil,
          upload_failed_text: nil,
          retry_button_text: nil,
          file_removed_text: nil,
          remove_button_text: nil,
          remove_button_content_text: nil,
          direct_upload: true,
          direct_upload_url: (self.direct_upload_url if direct_upload),
          **,
          &
        )
          Elements::Attachment.new(
            self,
            object_name,
            attribute_name,
            label:,
            caption:,
            hint:,
            form_group:,
            before_input:,
            after_input:,
            direct_upload_url:,
            choose_files_button_text:,
            drop_instruction_text:,
            multiple_files_chosen_text:,
            multiple_files_chosen_one_text:,
            multiple_files_chosen_other_text:,
            no_file_chosen_text:,
            entered_drop_zone_text:,
            left_drop_zone_text:,
            upload_succeeded_text:,
            upload_failed_text:,
            retry_button_text:,
            file_removed_text:,
            remove_button_text:,
            remove_button_content_text:,
            **,
            &
          ).html
        end

        # Generates a file input element for uploading documents.
        #
        # @example A upload field with label as a proc
        #   = f.govuk_document_field :data, label: -> { tag.h3('Upload your document') }
        #
        def govuk_document_field(attribute_name,
                                 label: {},
                                 caption: {},
                                 hint: {},
                                 form_group: {},
                                 mime_types: config.document_mime_types,
                                 **,
                                 &)
          if config.use_legacy_file_fields
            Elements::Document.new(
              self, object_name, attribute_name, label:, caption:, hint:, form_group:, mime_types:, **, &
            ).html
          else
            govuk_attachment_field(
              attribute_name, label:, caption:, hint:, form_group:, accept: mime_types&.join(","), **, &
            )
          end
        end

        # Generates a file input element with a preview for uploading images.
        #
        # @param attribute_name [Symbol] The name of the attribute
        # @param hint [Hash,Proc] The content of the hint. No hint will be added if 'text' is left +nil+.
        #   When a +Proc+ is supplied the hint will be wrapped in a +div+ instead of a +span+
        # @option hint text [String] the hint text
        # @option hint kwargs [Hash] additional arguments are applied as attributes to the hint
        # @param label [Hash,Proc] configures or sets the associated label content
        # @option label text [String] the label text
        # @option label size [String] the size of the label font, can be +xl+, +l+, +m+, +s+ or nil
        # @option label tag [Symbol,String] the label's wrapper tag, intended to allow labels to act as page headings
        # @option label hidden [Boolean] control the visibility of the label. Hidden labels will still be read by screen
        #   readers
        # @option label kwargs [Hash] additional arguments are applied as attributes on the +label+ element
        # @param caption [Hash] configures or sets the caption content which is inserted above the label
        # @option caption text [String] the caption text
        # @option caption size [String] the size of the caption, can be +xl+, +l+ or +m+. Defaults to +m+
        # @option caption kwargs [Hash] additional arguments are applied as attributes on the caption +span+ element
        # @option kwargs [Hash] kwargs additional arguments are applied as attributes to the +input+ element.
        # @param form_group [Hash] configures the form group
        # @option form_group classes [Array,String] sets the form group's classes
        # @option form_group kwargs [Hash] additional attributes added to the form group
        # @param & [Block] arbitrary HTML that will be rendered between the hint and the input
        # @return [ActiveSupport::SafeBuffer] HTML output
        #
        # @example An image field with injected content
        #   = f.govuk_image_field :incident_image,
        #     label: { text: 'Attach a picture of the incident' } do
        #
        #     p.govuk-inset-text
        #       | If you don't know exactly leave this section blank
        #
        # @example A image upload field with label as a proc
        #   = f.govuk_image_field :image, label: -> { tag.h3('Upload your image') }
        #
        def govuk_image_field(attribute_name,
                              label: {},
                              caption: {},
                              hint: {},
                              form_group: {},
                              mime_types: config.image_mime_types,
                              **,
                              &)
          if config.use_legacy_file_fields
            Elements::Image.new(
              self, object_name, attribute_name, label:, caption:, hint:, form_group:, mime_types:, **, &
            ).html
          else
            govuk_attachment_field(
              attribute_name, label:, caption:, hint:, form_group:, accept: mime_types&.join(","), **, &
            )
          end
        end

        # Keep track of whether we are inside a fieldset
        # This allows labels to default to bold ("s") normally but use the default otherwise
        def fieldset_context
          @fieldset_context ||= []
        end

        # URL for an attachment preview. ActiveStorage's representation route
        # lives in the application's route set, so engine-mounted forms
        # resolve it through main_app. Returns nil when no route is
        # available, in which case the figure renders without a preview.
        #
        # @param [ActiveStorage::Variant,ActiveStorage::VariantWithRecord,ActiveStorage::Preview] representation
        # @return [String,nil]
        def attachment_preview_url(representation)
          if @template.respond_to?(:rails_representation_path)
            @template.rails_representation_path(representation)
          elsif @template.respond_to?(:main_app) && @template.main_app.respond_to?(:rails_representation_path)
            @template.main_app.rails_representation_path(representation)
          end
        end

        private

        def direct_upload_url
          if @template.respond_to?(:rails_direct_uploads_url)
            @template.rails_direct_uploads_url
          elsif @template.respond_to?(:main_app) && @template.main_app.respond_to?(:rails_direct_uploads_url)
            @template.main_app.rails_direct_uploads_url
          end
        end

        def enum_values(attribute_name)
          object.class.defined_enums[attribute_name.to_s].keys
        end

        def enum_labels_for(attribute_name)
          model = object.class
          ->(value) { model.human_attribute_name("#{attribute_name}.#{value}") }
        end
      end
    end
  end
end
