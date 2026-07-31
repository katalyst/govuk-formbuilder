# frozen_string_literal: true

require "rails_helper"

# Exercises the GOV.UK Frontend javascript that the gem bundles and wires up.
# `govuk_formbuilder_init` enhances the page on load and observes <body>, so
# components arriving later — such as the guide's lazily-loaded example
# frames — are enhanced as they land, with no wiring in the consuming app.
# Each example below lives in its own lazy turbo frame, so a passing
# assertion proves the arrival path, not just page load.
RSpec.describe "GOV.UK Frontend javascript enhancements" do
  it "enhances a password input with a working show/hide toggle", :aggregate_failures do
    visit guide_page_path("password_input")

    within("#password_input__default") do
      password = find("input[name='profile[password]']")
      expect(password[:type]).to eq("password")

      # The formbuilder renders the toggle with `hidden`; PasswordInput removes
      # that attribute on init, so a *visible* toggle proves the enhancement ran.
      toggle = find(".govuk-password-input__toggle", wait: 5)
      expect(toggle).to be_visible

      # Clicking it reveals the password by switching the input to type=text.
      toggle.click
      expect(password[:type]).to eq("text")
    end
  end

  it "enhances a character-limited textarea with a live count message", :aggregate_failures do
    visit guide_page_path("textarea")

    # This example sets max_chars: 10 with threshold: 50, so the count message
    # stays hidden until half the limit is used, then tracks what remains.
    within("#textarea__max_chars_and_threshold") do
      fill_in "profile[education_history]", with: "hello"

      expect(page).to have_css(".govuk-character-count__status",
                               text: "5 characters remaining", wait: 5)
    end
  end

  it "enhances a javascript file upload with a Choose file button", :aggregate_failures do
    visit guide_page_path("file_upload")

    within("#file_upload__javascript") do
      expect(page).to have_css(".govuk-file-upload-button", wait: 5)
      expect(page).to have_button("Choose file")
    end
  end

  it "stays enhanced across a Turbo visit" do
    visit guide_page_path("textarea")

    within("#textarea__max_chars_and_threshold") do
      fill_in "profile[education_history]", with: "hello"
      expect(page).to have_css(".govuk-character-count__status", text: "5 characters remaining", wait: 5)
    end

    # A Turbo Drive visit replaces <body>, discarding the body-scoped
    # observers and guard; enhancement must re-establish on the new body
    # regardless of whether the init snippet's call is a no-op.
    click_link "Back to guide"
    click_link "Password input"

    within("#password_input__default") do
      toggle = find(".govuk-password-input__toggle", wait: 5)
      expect(toggle).to be_visible
    end
  end

  it "starts from the default export, so bundle consumers need one import" do
    visit guide_page_path("password_input")

    within("#password_input__default") do
      find(".govuk-password-input__toggle", wait: 5)
    end

    # Bundle consumers wire everything through the default export:
    # GOVUK.start(application). Called here without an application (and
    # after the page's own start), it must be a harmless no-op.
    started = page.evaluate_async_script(<<~JS)
      const done = arguments[0];
      import("@katalyst/govuk-formbuilder").then((m) => {
        if (typeof m.default.start !== "function") return done(false);
        m.default.start();
        done(true);
      });
    JS

    expect(started).to be(true)
  end

  it "tolerates repeated initAll calls without duplicating enhancements" do
    visit guide_page_path("password_input")

    within("#password_input__default") do
      find(".govuk-password-input__toggle", wait: 5)
    end

    # The layout's init snippet already ran; further calls are no-ops.
    page.evaluate_async_script(<<~JS)
      const done = arguments[0];
      import("@katalyst/govuk-formbuilder").then((m) => { m.initAll(); m.initAll(); done(true); });
    JS

    within("#password_input__default") do
      expect(page).to have_css(".govuk-password-input__toggle", count: 1)
    end
  end
end
