# frozen_string_literal: true

require "govuk_design_system_formbuilder"

module Katalyst
  module GOVUK
    module FormBuilder
      module Elements
        class Document < GOVUKDesignSystemFormBuilder::Base
          include ActionDispatch::Routing::RouteSet::MountedHelpers

          include GOVUKDesignSystemFormBuilder::Traits::Error
          include GOVUKDesignSystemFormBuilder::Traits::Hint
          include GOVUKDesignSystemFormBuilder::Traits::Label
          include GOVUKDesignSystemFormBuilder::Traits::Supplemental
          include GOVUKDesignSystemFormBuilder::Traits::HTMLAttributes
          include GOVUKDesignSystemFormBuilder::Traits::HTMLClasses

          include FormBuilder::Traits::File

          def initialize(builder, object_name, attribute_name, hint:, label:, caption:, form_group:, mime_types:,
                         **kwargs, &)
            super(builder, object_name, attribute_name, &)

            @mime_types      = mime_types
            @label           = label
            @caption         = caption
            @hint            = hint
            @html_attributes = kwargs.merge(file_input_options)
            @form_group      = form_group
          end

          def html
            GOVUKDesignSystemFormBuilder::Containers::FormGroup.new(
              *bound,
              **default_form_group_options(**@form_group),
            ).html do
              safe_join([label_element, preview, hint_element, error_element, file, destroy_element,
                         supplemental_content])
            end
          end

          def preview
            options = {}
            add_option(options, :data, "#{stimulus_controller}_target", "preview")
            add_option(options, :class, "preview-file")
            options[:hidden] = "" unless preview?

            tag.div(**options) do
              filename = @builder.object.send(@attribute_name).filename.to_s
              tag.p(filename, class: "preview-filename") + destroy_element_trigger
            end
          end

          private

          def stimulus_controller
            "govuk-document-field"
          end

          def form_group_class
            "govuk-document-field"
          end
        end
      end
    end
  end
end
