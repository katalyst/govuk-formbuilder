# frozen_string_literal: true

require "govuk_design_system_formbuilder"

module GOVUKDesignSystemFormBuilder
  module Builder

    # Generates a check box within a fieldset to be used as a boolean toggle for a single attribute.
    # The values are 1 (toggled on), and 0 (toggled off).
    #
    # @param attribute_name [Symbol] The name of the attribute
    # @param small [Boolean] controls whether small check boxes are used instead of regular-sized ones
    # @param hint [Hash,Proc] The content of the hint. No hint will be added if 'text' is left +nil+. When a +Proc+ is
    #   supplied the hint will be wrapped in a +div+ instead of a +span+
    # @option hint text [String] the hint text
    # @option hint kwargs [Hash] additional arguments are applied as attributes to the hint
    # @param link_errors [Boolean] controls whether this checkbox should be linked to from {#govuk_error_summary}
    # @option label text [String] the label text
    # @option label size [String] the size of the label font, can be +xl+, +l+, +m+, +s+ or nil
    # @option label tag [Symbol,String] the label's wrapper tag, intended to allow labels to act as page headings
    # @option label hidden [Boolean] control the visibility of the label. Hidden labels will still be read by screenreaders
    # @option label kwargs [Hash] additional arguments are applied as attributes on the +label+ element
    # @option kwargs [Hash] kwargs additional arguments are applied as attributes to the +input+ element
    # @param block [Block] any HTML passed in will form the contents of the fieldset
    # @return [ActiveSupport::SafeBuffer] HTML output
    #
    # @example A single check box for terms and conditions
    #   = f.govuk_boolean_checkbox_field :terms_agreed,
    #     link_errors: true,
    #     label: { text: 'Do you agree with our terms and conditions?' },
    #     hint: { text: 'You will not be able to proceed unless you do' }
    #
    def govuk_boolean_checkbox_field(attribute_name, small: true, hint: {}, label: {}, link_errors: false, **kwargs, &block)
      govuk_check_boxes_fieldset(attribute_name, legend: nil, multiple: false, small: small) do
        govuk_check_box(attribute_name, 1, 0,
                        hint:        hint,
                        label:       label,
                        link_errors: link_errors,
                        multiple:    false,
                        exclusive:   false,
                        **kwargs, &block)
      end
    end
  end
end
