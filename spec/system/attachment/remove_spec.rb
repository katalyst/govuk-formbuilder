# frozen_string_literal: true

require "rails_helper"

# Removing an attachment figure with JavaScript. Together the examples pin
# the behaviour of the remove control:
#
#   * each figure offers a remove control named after its file
#   * removing deletes the figure from the DOM so its signed id no longer
#     submits; Rails' auto-blank still clears an emptied has_many
#   * removing a has_one's figure still submits the detach — removing with
#     JavaScript equals choosing the remove option without it, so a required
#     attachment surfaces its presence error instead of silently surviving
#   * focus moves to the field's upload button, whose status summarises
#     what remains — never lost to <body>
#   * removal is announced through the field's announcements region, naming
#     the file — the figure's own live region disappears with the figure
RSpec.describe "Removing an attachment", :aggregate_failures do
  include AttachmentFieldHelpers

  let(:profile) do
    create(:profile).tap do |p|
      %w[first.png second.png].each do |filename|
        p.gallery.attach(io: File.open(file_fixture("avatar.png")), filename:, content_type: "image/png")
      end
    end
  end

  it "offers a remove control on each figure whose accessible name includes the filename" do
    visit edit_profile_path(profile)

    %w[first.png second.png].each do |filename|
      within(".govuk-attachment", text: filename) do
        expect(page).to have_button("Remove #{filename}")
      end
    end
  end

  it "removes the figure so its value no longer submits" do
    visit edit_profile_path(profile)

    click_button "Remove first.png"

    expect(page).to have_no_css(".govuk-attachment", text: "first.png")
    expect(page).to have_css(".govuk-attachment", text: "second.png")

    click_button "Continue"

    expect(page).to have_current_path(profile_path(profile))
    expect(profile.reload.gallery.blobs.map { |blob| blob.filename.to_s }).to eq(%w[second.png])
  end

  it "clears the association when every figure is removed" do
    visit edit_profile_path(profile)

    click_button "Remove first.png"
    click_button "Remove second.png"

    # Scoped: the required avatar keeps its own figure on the page.
    expect(gallery_field).to have_no_css(".govuk-attachment")

    click_button "Continue"

    expect(page).to have_current_path(profile_path(profile))
    expect(profile.reload.gallery).not_to be_attached
  end

  it "detaches a removed has_one on submit, surfacing the required error" do
    visit edit_profile_path(profile)

    click_button "Remove avatar.png"

    expect(avatar_field).to have_no_css(".govuk-attachment")

    click_button "Continue"

    expect(page).to have_css(".govuk-error-summary a", text: /blank/i)
    expect(page).to have_css(
      ".govuk-form-group--error:has(input[name='profile[avatar]']) p.govuk-error-message",
      text: /blank/i,
    )
  end

  it "detaches a removed optional has_one on submit" do
    profile.cv.attach(io: File.open(file_fixture("cv.pdf")), filename: "cv.pdf", content_type: "application/pdf")
    visit edit_profile_path(profile)

    click_button "Remove cv.pdf"

    expect(cv_field).to have_no_css(".govuk-attachment")

    click_button "Continue"

    expect(page).to have_current_path(profile_path(profile))
    expect(profile.reload.cv).not_to be_attached
  end

  it "moves focus to the field's upload button" do
    visit edit_profile_path(profile)
    on_upload_button = %(document.activeElement.matches("button#profile-gallery-field"))

    click_button "Remove first.png"

    # Mid-gallery and last removal alike: the upload button's status is the
    # summary of what remains, and its focus reading carries the updated
    # count — a sibling figure's reading would not. Never <body>, and not
    # some other field's input.
    expect(page.evaluate_script(on_upload_button)).to be(true)

    click_button "Remove second.png"

    expect(page.evaluate_script(on_upload_button)).to be(true)
  end

  it "announces the removal, naming the file" do
    visit edit_profile_path(profile)

    click_button "Remove first.png"

    expect(announcements_region(gallery_field)).to have_text("first.png removed")
  end
end
