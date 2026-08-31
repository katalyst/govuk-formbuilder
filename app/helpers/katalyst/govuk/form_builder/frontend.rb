# frozen_string_literal: true

module Katalyst
  module GOVUK
    module FormBuilder
      module Frontend
        # Marks the page as JS-capable and enhances govuk-frontend components,
        # on load and as the DOM changes (Turbo morphs, lazily-loaded frames,
        # stream inserts). Render at the end of <body>; on a Turbo replace
        # render the snippet re-executes with the new body, and everything it
        # sets up is scoped to the body element it ran against.
        # rubocop:disable-next Rails/OutputSafety
        def govuk_formbuilder_init
          tag.script type: "module", nonce: request.content_security_policy_nonce do
            <<~JS.html_safe
              import {initAll} from "@katalyst/govuk-formbuilder";
              initAll(#{govuk_formbuilder_init_options});
            JS
          end
        end

        private

        # The bundle's own default is govuk; only a non-default brand renders.
        def govuk_formbuilder_init_options
          brand = GOVUKDesignSystemFormBuilder.brand

          brand.to_s == "govuk" ? "" : "{brand: #{brand.to_json}}"
        end
      end
    end
  end
end
