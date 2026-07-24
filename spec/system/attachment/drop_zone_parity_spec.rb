# frozen_string_literal: true

require "rails_helper"

# The attachment field replaces govuk-frontend's FileUpload JavaScript,
# borrowing its markup conventions and i18n strings: the field must look,
# read, and announce like the component it replaces. govuk-frontend is the
# reference implementation, so this spec enhances a plain govuk_file_field
# with govuk-frontend's own JS beside our attachment field and compares the
# two live drop zones. A govuk-frontend upgrade that changes the injected UI
# — or a change of ours — surfaces as a diff instead of silent drift.
#
# The intended delta is scrubbed explicitly below; anything else is drift.
RSpec.describe "Drop zone parity with govuk-frontend" do
  include AttachmentFieldHelpers
  include CanonicalMarkup

  let(:profile) { create(:profile) }

  it "builds the same drop zone govuk-frontend's FileUpload builds" do
    visit example_path("file_upload", "javascript")

    # govuk-frontend inserts its announcements region after the drop zone;
    # capture both so the announcements comparison below sees it.
    reference = find("[data-module='govuk-file-upload']:has(.govuk-file-upload-button)")
                  .evaluate_script("this.outerHTML + this.nextElementSibling.outerHTML")

    visit example_path("attachment", "enhancement")

    field = attachment_field("profile[avatar]")
    field.find(".govuk-file-upload-button", wait: 5)
    ours  = field.evaluate_script("this.outerHTML")

    expect(canonical_drop_zone(ours)).to eq(canonical_drop_zone(reference))
  end

  # Canonicalise a captured drop zone: the wrapper, intended differences
  # scrubbed, with the announcements region in a fixed final position — ours
  # renders inside the wrapper so scoped finds and morph re-enhancement keep
  # it, govuk-frontend's sits just after the drop zone. Placement differs by
  # design; presence and shape must not.
  def canonical_drop_zone(html)
    fragment      = Nokogiri::HTML5.fragment(html)
    announcements = fragment.at_css(".govuk-file-upload-announcements")&.unlink
    wrapper       = fragment.at_css("div")

    scrub_enhancement_markers(wrapper)
    scrub_attachment_extensions(wrapper)

    canonical_markup(wrapper, announcements)
  end

  private

  # The enhancement mechanism is the one wrapper-level difference:
  # govuk-frontend enhances data-module (stamping an -init flag when done),
  # our Stimulus controller enhances data-controller.
  def scrub_enhancement_markers(wrapper)
    wrapper.remove_attribute("data-module")
    wrapper.remove_attribute("data-govuk-file-upload-init")
    wrapper.remove_attribute("data-controller")
  end

  # The attachment field's extensions over a plain file upload: the blank
  # keeper that lets a removed attachment detach, the direct-upload endpoint,
  # and the accept filter the example's image field adds. Remove a line here
  # to surface that difference in the diff instead.
  def scrub_attachment_extensions(wrapper)
    wrapper.css("input[type=hidden]").each(&:unlink)
    wrapper.at_css("input[type=file]")&.remove_attribute("data-direct-upload-url")
    wrapper.at_css("input[type=file]")&.remove_attribute("accept")
  end
end
