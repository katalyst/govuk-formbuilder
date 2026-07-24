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
        # rubocop:disable Rails/OutputSafety
        def govuk_formbuilder_init
          tag.script type: "module", nonce: request.content_security_policy_nonce do
            <<~JS.html_safe
              import {init} from "@katalyst/govuk-formbuilder";
              init({brand: #{GOVUKDesignSystemFormBuilder.brand.to_json}});
            JS
          end
        end
        # rubocop:enable Rails/OutputSafety
      end
    end
  end
end
