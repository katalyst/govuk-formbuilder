# frozen_string_literal: true

module Katalyst
  module GOVUK
    module FormBuilder
      module Frontend
        def govuk_formbuilder_init
          tag.script type: "module", nonce: request.content_security_policy_nonce do
            <<~JS.html_safe
              document.body.classList.add("js-enabled");
              import {initAll} from "@katalyst/govuk-formbuilder";
              initAll();
            JS
          end
        end
      end
    end
  end
end
