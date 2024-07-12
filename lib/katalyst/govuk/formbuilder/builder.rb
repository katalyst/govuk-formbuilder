# frozen_string_literal: true

module Katalyst
  module GOVUK
    module Formbuilder
      module Builder
        extend ActiveSupport::Concern

        included do
          # Overwrite GOVUK default to set small to true
          # @see GOVUKDesignSystemFormBuilder::Builder#govuk_radio_buttons_fieldset
          def govuk_radio_buttons_fieldset(attribute_name, hint: {}, legend: {}, caption: {}, inline: false,
                                           small: true, form_group: {}, **kwargs, &block)
            GOVUKDesignSystemFormBuilder::Containers::RadioButtonsFieldset.new(
              self, object_name, attribute_name,
              hint:, legend:, caption:, inline:, small:, form_group:,
              **kwargs, &block
            ).html
          end

          # Overwrite GOVUK default to set small to true
          # @see GOVUKDesignSystemFormBuilder::Builder#govuk_collection_check_boxes
          def govuk_collection_check_boxes(attribute_name, collection, value_method, text_method, hint_method = nil,
                                           hint: {}, legend: {}, caption: {}, small: true, form_group: {},
                                           include_hidden: config.default_collection_check_boxes_include_hidden,
                                           **kwargs, &block)
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
              **kwargs,
              &block
            ).html
          end

          # Overwrite GOVUK default to set small to true
          # @see GOVUKDesignSystemFormBuilder::Builder#govuk_check_boxes_fieldset
          def govuk_check_boxes_fieldset(attribute_name, legend: {}, caption: {}, hint: {}, small: true, form_group: {},
                                         multiple: true, **kwargs, &block)
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
              **kwargs,
              &block
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
                                  small: true, hint: {}, label: {}, link_errors: false, **kwargs, &block)
          govuk_check_boxes_fieldset(attribute_name, legend: nil, multiple: false, small:) do
            fieldset_context.pop # undo push from fieldset extension, labels should be bold unless already nested
            checkbox = govuk_check_box(attribute_name, value, unchecked_value,
                                       hint:,
                                       label:,
                                       link_errors:,
                                       multiple:    false,
                                       exclusive:   false,
                                       **kwargs, &block)
            fieldset_context.push attribute_name # restore push from fieldset
            checkbox
          end
        end

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
        # @param block [Block] arbitrary HTML that will be rendered between the hint and the input
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
        # @example A rich text area with a custom direct upload url and a custom stimulus controller
        #   = f.govuk_rich_text_area :description,
        #     data: {
        #             direct_upload_url: direct_uploads_url,
        #             controller:        "content--editor--trix",
        #             action:            "trix-initialize->content--editor--trix#trixInitialize",
        #           }
        #
        def govuk_rich_text_area(attribute_name, hint: {}, label: {}, caption: {}, form_group: {}, **, &)
          Elements::RichTextArea.new(
            self, object_name, attribute_name,
            hint:, label:, caption:, form_group:, **, &
          ).html
        end

        # Keep track of whether we are inside a fieldset
        # This allows labels to default to bold ("s") normally but use the default otherwise
        def fieldset_context
          @fieldset_context ||= []
        end
      end
    end
  end
end
