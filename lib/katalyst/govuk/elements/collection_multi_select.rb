# frozen_string_literal: true

require "action_view/helpers/tags/collection_helpers"

module ActionView
  module Helpers
    module FormOptionsHelper
      # Returns <tt><multi-select></tt> and <tt><option></tt> tags for the collection of existing return values of
      # +method+ for +object+'s class. The values returned from calling +method+ on the instance +object+ will
      # be selected. If calling +method+ returns +nil+, no selection is made without including <tt>:prompt</tt>
      # or <tt>:include_blank</tt> in the +options+ hash.
      #
      # The <tt>:value_method</tt> and <tt>:text_method</tt> parameters are methods to be called on each member
      # of +collection+. The return values are used as the +value+ attribute and contents of each
      # <tt><option></tt> tag, respectively. They can also be any object that responds to +call+, such
      # as a +proc+, that will be called for each member of the +collection+ to
      # retrieve the value/text.
      #
      # Example object structure for use with this method:
      #
      #   class Product < ActiveRecord::Base
      #     has_and_belongs_to_many :suppliers
      #   end
      #
      #   class Supplier < ActiveRecord::Base
      #     attribute :name
      #   end
      #
      # Sample usage (selecting the associated Suppliers for an instance of Product, <tt>@product</tt>):
      #
      #   collection_multi_select(:product, :supplier_ids, Supplier.all, :id, :name)
      #
      # If <tt>@product.supplier_ids</tt> is already <tt>[1, 3]</tt>, this would return:
      #   <multi-select name="product[supplier_ids]" id="product_supplier_ids">
      #     <input type=hidden name="product[supplier_ids][]" value />
      #     <input type=hidden name="product[supplier_ids][]" value="1" />
      #     <input type=hidden name="product[supplier_ids][]" value="3" />
      #     <span class="value">ACME INC (+1 more)</span>
      #     <datalist id="product_supplier_ids_list">
      #       <option value="1" selected>ACME INC</option>
      #       <option value="2">Katalyst Interactive</option>
      #       <option value="3" selected>Universal Exports</option>
      #     </ul>
      #   </multi-select>
      def collection_multi_select(object, method, collection, value_method, text_method, options = {},
html_options = {})
        Katalyst::GOVUK::Elements::CollectionMultiSelect
          .new(object, method, self, collection, value_method,
               text_method, options, html_options).render
      end
    end

    class FormBuilder
      # Wraps ActionView::Helpers::FormOptionsHelper#collection_multi_select for form builders:
      #
      #   <%= form_for @post do |f| %>
      #     <%= f.collection_multi_select :suppliers, Suppliers.all, :id, :name %>
      #     <%= f.submit %>
      #   <% end %>
      #
      # Please refer to the documentation of the base helper for details.
      def collection_multi_select(method, collection, value_method, text_method, options = {}, html_options = {})
        @template.collection_multi_select(@object_name, method, collection, value_method, text_method,
                                          objectify_options(options),
                                          @default_html_options.merge(html_options))
      end
    end
  end
end

module Katalyst
  module GOVUK
    module Elements
      class CollectionMultiSelect < ActionView::Helpers::Tags::Base
        attr_reader :html_options

        delegate_missing_to :@template_object

        def initialize(object_name, method_name, template_object, collection, value_method, text_method,
                       options, html_options)
          @collection   = collection
          @value_method = value_method
          @text_method  = text_method
          @html_options = html_options.merge(multiple: "").stringify_keys

          super(object_name, method_name, template_object, options)

          @html_options = @html_options.merge(multiple: "").stringify_keys
          add_default_name_and_id(@html_options)
        end

        def render
          content_tag("multi-select", multi_select_options) do
            input_tags + summary_tag + datalist_tag
          end
        end

        def input_tags
          capture do
            # ensure that there's a placeholder in case all values are removed
            concat(tag("input",
                       disabled: (@options.fetch(:include_blank?, true) ? nil : "disabled"),
                       name:     html_options["name"],
                       type:     "hidden",
                       value:    ""))
            selected_values.dup.each do |value|
              concat(tag("input",
                         disabled: html_options["disabled"],
                         name:     html_options["name"],
                         type:     "hidden",
                         value:))
            end
          end
        end

        def summary_tag
          content_tag(:div,
                      class:       build_classes("summary", "placeholder" => selected_values.none?),
                      tabindex:    0,
                      aria:        { controls: datalist_id },
                      data:        { multi_select_target: "summary" },
                      placeholder: prompt_text(@options[:placeholder])) do
            text = if first_selected.present?
                     value_for_collection(first_selected, @text_method)
                   else
                     prompt_text(@options[:placeholder])
                   end
            case selected_values.count
            when 0, 1
              text
            else
              "#{text} (+#{selected_values.count - 1} more)"
            end
          end
        end

        def datalist_tag
          content_tag(:ul,
                      id:   datalist_id,
                      role: "listbox",
                      aria: { expanded: "false" },
                      data: { multi_select_target: "datalist" }) do
            options_from_collection(@collection, @value_method, @text_method,
                                    selected:,
                                    disabled:    @options[:disabled],
                                    placeholder: @options[:placeholder])
          end
        end

        private

        def selected
          @options.fetch(:selected) { value }&.reject(&:blank?)
        end

        def selected_values
          @selected_values ||=
            extract_values_from_collection(@collection, @value_method, selected)&.map(&:to_s) || []
        end

        def multi_select_options
          options = html_options.dup
          options.delete("name")
          options["data"] = options["data"]&.stringify_keys || {}
          add_for_stimulus options, "controller", "multi-select"
          add_for_stimulus options, "action", "focusin->multi-select#focus"
          add_for_stimulus options, "action", "focusout->multi-select#blur"
          add_for_stimulus options, "action", "click->multi-select#click"
          add_for_stimulus options, "action", "keydown->multi-select#keydown"
          options
        end

        def datalist_id
          "#{html_options['id']}_options"
        end

        # Method implementation duplicated from
        # ActionView::Helpers::FormOptionsHelper#options_from_collection_for_select
        # Option tag replaced with li tag due to rendering issues on iOS platforms
        def options_from_collection(collection, value_method, text_method, selected_options = nil)
          options = collection.map do |element|
            [value_for_collection(element, text_method), value_for_collection(element, value_method),
             option_html_attributes(element)]
          end
          selected, disabled = extract_selected_and_disabled(selected_options)
          select_deselect    = {
            selected: extract_values_from_collection(collection, value_method, selected),
            disabled: extract_values_from_collection(collection, value_method, disabled),
          }

          selected, disabled = extract_selected_and_disabled(select_deselect).map do |r|
            Array(r).map(&:to_s)
          end

          capture do
            options.each { |element| concat option_tag(element, selected, disabled) }
          end
        end

        def option_tag(element, selected, disabled)
          html_attributes = option_html_attributes(element)
          text, value     = option_text_and_value(element).map(&:to_s)

          html_attributes[:selected] ||= option_value_selected?(value, selected)
          html_attributes[:disabled] ||= disabled && option_value_selected?(value, disabled)
          html_attributes[:value]    = value
          html_attributes[:role]     = "option"
          html_attributes[:tabindex] = "-1"
          add_for_stimulus(html_attributes, "multi_select_target", "option")

          tag_builder.content_tag_string(:li, text, html_attributes)
        end

        def first_selected
          Array(@collection).find do |item|
            selected_values.include?(value_for_collection(item, @value_method).to_s)
          end
        end

        def add_for_stimulus(options, attr, value)
          data       = options["data"] ||= {}
          data[attr] = [data[attr], value].compact.join(" ")
        end

        def build_classes(*args, **kwargs)
          (args + kwargs.map { |k, v| k if v }).compact
        end
      end
    end
  end
end
