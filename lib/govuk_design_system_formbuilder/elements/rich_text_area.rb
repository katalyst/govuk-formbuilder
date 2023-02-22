# frozen_string_literal: true

require "govuk_design_system_formbuilder"

module GOVUKDesignSystemFormBuilder
  module Elements
    class RichTextArea < Base
      using PrefixableArray

      include Traits::Error
      include Traits::Hint
      include Traits::Label
      include Traits::Supplemental
      include Traits::HTMLAttributes
      include Traits::HTMLClasses

      def initialize(builder, object_name, attribute_name, hint:, label:, caption:, form_group:, **kwargs, &block)
        super(builder, object_name, attribute_name, &block)

        @label           = label
        @caption         = caption
        @hint            = hint
        @form_group      = form_group
        @html_attributes = kwargs
      end

      def html
        Containers::FormGroup.new(*bound, **@form_group).html do
          safe_join([label_element, supplemental_content, hint_element, error_element, rich_text_area])
        end
      end

      private

      def rich_text_area
        @builder.rich_text_area(@attribute_name, **attributes(@html_attributes))
      end

      def classes
        build_classes(%(richtextarea), %(richtextarea--error) => has_errors?).prefix(brand)
      end

      def options
        {
          id:    field_id(link_errors: true),
          class: classes,
          aria:  { describedby: combine_references(hint_id, error_id, supplemental_id) },
        }
      end
    end
  end
end

module GOVUKDesignSystemFormBuilder
  module Builder
    # Generates a pair of +trix-toolbar+ and +trix-editor+ elements with a label, optional hint. Requires action-text to
    # be correctly setup in the application
    #
    # @param attribute_name [Symbol] The name of the attribute
    # @param hint [Hash,Proc] The content of the hint. No hint will be added if 'text' is left +nil+. When a +Proc+ is
    #   supplied the hint will be wrapped in a +div+ instead of a +span+
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
    # @option kwargs [Hash] kwargs additional arguments are applied as attributes to the +trix-editor+ element. This is
    #   picked up and handled by the action-text gem
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
    def govuk_rich_text_area(attribute_name, hint: {}, label: {}, caption: {}, form_group: {}, **kwargs, &block)
      Elements::RichTextArea.new(self, object_name, attribute_name,
                                 hint:, label:, caption:, form_group:, **kwargs, &block).html
    end
  end
end
