# frozen_string_literal: true

require "rails_helper"

# The dummy app runs under a strict, nonce-based CSP (script-src uses
# strict-dynamic + nonce; no external hosts). This proves the form builder —
# importmap scripts, the govuk_formbuilder_init module, hotwire_combobox, trix
# and the self-hosted fonts — all work without tripping the policy.
RSpec.describe "Content Security Policy" do
  before do
    # Runs before any page script (isolated from the page CSP), so it catches
    # violations that occur during initial load.
    page.driver.browser.evaluate_on_new_document(<<~JS)
      window.__cspViolations = [];
      document.addEventListener("securitypolicyviolation", (event) => {
        window.__cspViolations.push(
          event.effectiveDirective + " blocked " + (event.blockedURI || event.sourceFile),
        );
      });
    JS
  end

  it "renders and enhances the form with no violations", :aggregate_failures do
    visit new_profile_path

    # Exercise the interactive components that load scripts, styles and fonts.
    expect(page).to have_css("body.js-enabled", wait: 5)
    find("[role=combobox]").click
    expect(page).to have_css("[role=option]", text: "Australia")
    expect(page).to have_css("trix-editor")

    expect(page.evaluate_script("window.__cspViolations")).to eq([])
  end
end
