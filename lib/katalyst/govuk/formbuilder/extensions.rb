# frozen_string_literal: true

require "govuk_design_system_formbuilder"

module Katalyst
  module GOVUK
    module Formbuilder
      module Extensions
        module Fieldset
          def initialize(builder, object_name = nil, attribute_name = nil, &)
            builder.fieldset_context << attribute_name

            super

            builder.fieldset_context.pop
          end
        end
      end
    end
  end
end

module GOVUKDesignSystemFormBuilder
  module Builder
    # Keep track of whether we are inside a fieldset
    # This allows labels to default to bold ("s") normally but use the default otherwise
    def fieldset_context
      @fieldset_context ||= []
    end

    # Overwrite GOVUK default to set small to true
    # @see GOVUKDesignSystemFormBuilder::Builder#govuk_collection_radio_buttons
    def govuk_collection_radio_buttons(attribute_name, collection, value_method, text_method = nil, hint_method = nil,
                                       hint: {}, legend: {}, caption: {}, inline: false, small: true, bold_labels: nil,
                                       include_hidden: config.default_collection_radio_buttons_include_hidden,
                                       form_group: {}, **kwargs, &block)
      Elements::Radios::Collection.new(
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
        **kwargs,
        &block
      ).html
    end

    # Overwrite GOVUK default to set small to true
    # @see GOVUKDesignSystemFormBuilder::Builder#govuk_radio_buttons_fieldset
    def govuk_radio_buttons_fieldset(attribute_name, hint: {}, legend: {}, caption: {}, inline: false, small: true,
                                     form_group: {}, **kwargs, &block)
      Containers::RadioButtonsFieldset.new(self, object_name, attribute_name,
                                           hint:, legend:, caption:, inline:, small:, form_group:,
                                           **kwargs, &block).html
    end

    # Overwrite GOVUK default to set small to true
    # @see GOVUKDesignSystemFormBuilder::Builder#govuk_collection_check_boxes
    def govuk_collection_check_boxes(attribute_name, collection, value_method, text_method, hint_method = nil,
                                     hint: {}, legend: {}, caption: {}, small: true, form_group: {},
                                     include_hidden: config.default_collection_check_boxes_include_hidden,
                                     **kwargs, &block)
      Elements::CheckBoxes::Collection.new(
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
      Containers::CheckBoxesFieldset.new(
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

  # Extend Traits::Label set the default size to small for non-nested labels.
  module Traits
    module Label
      private

      def label_content
        default = @builder.fieldset_context.count.positive? ? {} : { size: "s" }

        case @label
        when Hash
          default.merge(@label)
        when Proc
          default.merge(content: @label)
        else
          fail(ArgumentError, %(label must be a Proc or Hash))
        end
      end
    end
  end

  # Extend Elements::Label to add support for human_attribute_name as a fallback
  module Elements
    class Label
      def retrieve_text(option_text, hidden)
        text = option_text.presence ||
          localised_text(:label).presence ||
          human_attribute_name.presence ||
          @attribute_name.to_s.humanize.capitalize.presence

        if hidden
          tag.span(text, class: %(#{brand}-visually-hidden))
        else
          text
        end
      end

      def human_attribute_name
        return unless @object_name.present? && @attribute_name.present?
        return unless @builder.object&.class.respond_to?(:human_attribute_name)

        @builder.object.class.human_attribute_name(@attribute_name)
      end
    end
  end

  module Containers
    class Fieldset
      include Katalyst::GOVUK::Formbuilder::Extensions::Fieldset
    end

    class CheckBoxesFieldset
      include Katalyst::GOVUK::Formbuilder::Extensions::Fieldset
    end

    class RadioButtonsFieldset
      include Katalyst::GOVUK::Formbuilder::Extensions::Fieldset
    end
  end
end
