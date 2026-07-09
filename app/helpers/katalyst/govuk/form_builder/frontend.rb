# frozen_string_literal: true

module Katalyst
  module GOVUK
    module FormBuilder
      module Frontend
        # rubocop:disable Rails/OutputSafety
        def govuk_formbuilder_init
          tag.script type: "module", nonce: request.content_security_policy_nonce do
            <<~JS.html_safe
              document.body.classList.toggle("js-enabled", true);
              document.body.classList.toggle("govuk-frontend-supported", ('noModule' in HTMLScriptElement.prototype));
              import {initAll} from "@katalyst/govuk-formbuilder";
              initAll();
            JS
          end
        end
        # rubocop:enable Rails/OutputSafety
      end
    end
  end
end
