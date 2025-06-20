# frozen_string_literal: true

require "govuk_design_system_formbuilder"

module Katalyst
  module GOVUK
    module FormBuilder
      module Traits
        module File
          extend ActiveSupport::Concern

          protected

          def stimulus_controller_actions
            <<~ACTIONS.gsub(/\s+/, " ").freeze
              dragover->#{stimulus_controller}#dragover
              dragenter->#{stimulus_controller}#dragenter
              dragleave->#{stimulus_controller}#dragleave
              drop->#{stimulus_controller}#drop
            ACTIONS
          end

          def file
            previous_input = @builder.hidden_field(@attribute_name, id: nil, value: value.signed_id) if attached?
            file_input     = @builder.file_field(@attribute_name, attributes(@html_attributes))

            safe_join([previous_input, file_input])
          end

          def destroy_element
            return if @html_attributes[:optional].blank?

            @builder.fields_for(:"#{@attribute_name}_attachment") do |form|
              form.hidden_field :_destroy, value: false, data: { "#{stimulus_controller}_target" => "destroy" }
            end
          end

          def destroy_element_trigger
            return if @html_attributes[:optional].blank?

            content_tag(:button, "", class: "file-destroy", data: { action: "#{stimulus_controller}#setDestroy" })
          end

          def preview_url
            preview? ? main_app.polymorphic_path(value, only_path: true) : ""
          end

          def preview?
            attached?
          end

          def attached?
            value&.attached? && value.blob.persisted?
          end

          def value
            @builder.object.send(@attribute_name)
          end

          def file_input_options
            default_file_input_options = options

            add_option(default_file_input_options, :accept, @mime_types.join(","))
            add_option(default_file_input_options, :data, :action, "change->#{stimulus_controller}#onUpload")

            default_file_input_options
          end

          def options
            {
              id:    field_id(link_errors: true),
              class: classes,
              aria:  { describedby: combine_references(hint_id, error_id, supplemental_id) },
            }
          end

          using GOVUKDesignSystemFormBuilder::PrefixableArray

          def classes
            build_classes(%(file-upload), %(file-upload--error) => has_errors?).prefix(brand)
          end

          def default_form_group_options(**form_group_options)
            add_option(form_group_options, :class, "govuk-form-group #{form_group_class}")
            add_option(form_group_options, :data, :controller, stimulus_controller)
            add_option(form_group_options, :data, :action, stimulus_controller_actions)
            add_option(form_group_options, :data, :"#{stimulus_controller}_mime_types_value",
                       @mime_types.to_json)

            form_group_options
          end

          def add_option(options, key, *path)
            if path.length > 1
              add_option(options[key] ||= {}, *path)
            else
              options[key] = [options[key], *path].compact.join(" ")
            end
          end
        end
      end
    end
  end
end
