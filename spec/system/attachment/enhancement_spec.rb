# frozen_string_literal: true

require "rails_helper"

# The attachment field replaces govuk-frontend's FileUpload JavaScript, so its
# accessibility contract is the compatibility bar. When the controller injects
# the pseudo upload button it must, like FileUpload:
#
#   * give the field label an id so the button's `aria-labelledby` resolves
#     (the label otherwise has only a `for`, and the button references an id
#     that would not exist)
#   * copy the input's `aria-describedby` (hint / error ids) onto the button,
#     so the same descriptions reach the control the user operates
#   * mirror the input's `disabled` state onto the button and wrapper, and
#     keep them in step when the input's `disabled` attribute changes at
#     runtime (a MutationObserver)
#
# These configurations are not present on the profile form, so they are driven
# through a test-support example (examples/attachment/enhancement).
RSpec.describe "Attachment field enhancement", :aggregate_failures do
  include AttachmentFieldHelpers

  let(:page_path) { example_path("attachment", "enhancement") }

  it "gives the label an id so the button's accessible name resolves" do
    visit page_path

    field  = attachment_field("profile[avatar]")
    button = field.find(".govuk-file-upload-button", wait: 5)

    # Every id the button is labelled by must resolve to an element on the
    # page — no dangling reference.
    button["aria-labelledby"].split.each do |id|
      expect(page).to have_css("##{id}", visible: :all)
    end

    # ...and the first of those is the field's own label, which the enhancement
    # has given an id.
    expect(page).to have_css("label#profile-avatar-field-label", text: "Profile photo")
  end

  it "copies the input's aria-describedby onto the button" do
    visit page_path

    field  = attachment_field("profile[avatar]")
    button = field.find(".govuk-file-upload-button", wait: 5)
    input  = field.find("input[type=file]", visible: :all)

    described = button["aria-describedby"]

    expect(described).to eq(input["aria-describedby"])
    # The referenced element is the field's hint, so the same description the
    # input carried now describes the button.
    expect(page).to have_css("##{described}", text: "Upload a clear colour photograph", visible: :all)
  end

  it "mirrors the input's disabled state onto the button and wrapper" do
    visit page_path

    field = attachment_field("profile[cv]")

    expect(field).to have_css(".govuk-file-upload-button[disabled]", wait: 5)
    expect(page).to have_css(
      ".govuk-file-upload-wrapper--disabled:has(input[name='profile[cv]'])",
      visible: :all,
    )
  end

  it "keeps the button in step when the input is enabled at runtime" do
    visit page_path

    field = attachment_field("profile[cv]")
    expect(field).to have_css(".govuk-file-upload-button[disabled]", wait: 5)

    # A consumer (or a Turbo refresh) re-enables the input; the observer keeps
    # the injected button and wrapper in step.
    input = field.find("input[type=file]", visible: :all)
    page.execute_script("arguments[0].disabled = false", input)

    expect(field).to have_css(".govuk-file-upload-button:not([disabled])")
    expect(page).to have_no_css(
      ".govuk-file-upload-wrapper--disabled:has(input[name='profile[cv]'])",
      visible: :all,
    )
  end
end
