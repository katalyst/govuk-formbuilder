# frozen_string_literal: true

require "rails_helper"

# Exercises the GOV.UK Frontend javascript that the gem bundles and wires up.
# `initAll` (see Frontend#govuk_formbuilder_init) instantiates the upstream
# components on page load, and the dummy app re-runs it on `turbo:frame-load`
# (spec/dummy/app/javascript/application.js) so components inside the guide's
# lazily-loaded example frames are enhanced too. Each example below lives in
# its own lazy turbo frame, so a passing assertion proves both paths.
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
end
