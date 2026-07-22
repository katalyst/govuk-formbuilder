# frozen_string_literal: true

require "rails_helper"

# The enhanced field without a direct-upload endpoint (direct_upload: false,
# or no route available): selection still previews and counts, but no upload
# starts and nothing claims the files — they stay in the input and submit as
# ordinary multipart.
RSpec.describe "Attachment field without direct upload", :aggregate_failures do
  include AttachmentFieldHelpers
  include DirectUploadHelpers

  let(:profile) { create(:profile) }

  before do
    Capybara.enable_aria_label = true
    disable_direct_uploads
  end

  after do
    Capybara.enable_aria_label = false
  end

  it "previews the selection without starting an upload" do
    visit edit_profile_path(profile)

    choose_gallery_file("avatar.png")

    expect(gallery_field).to have_css("figure.govuk-attachment .filename", text: "avatar.png")

    # No upload lifecycle: the figure never enters an upload state.
    expect(gallery_field).to have_no_css("figure.govuk-attachment[data-state]")
    expect(gallery_field).to have_no_css("figure.govuk-attachment progress")
  end

  it "counts the selection in the status region" do
    visit edit_profile_path(profile)

    choose_gallery_file("avatar.png")

    expect(status_region(gallery_field)).to have_text("1 file chosen")
  end

  it "submits the selection as ordinary multipart" do
    visit edit_profile_path(profile)

    choose_gallery_file("avatar.png")
    click_button "Continue"

    expect(page).to have_current_path(profile_path(profile))
    expect(profile.reload.gallery.blobs.map { |blob| blob.filename.to_s }).to eq(%w[avatar.png])
  end

  it "removes the file from the submission when its preview is removed" do
    visit edit_profile_path(profile)

    choose_gallery_file("avatar.png")
    # Scoped: the required avatar's own figure offers "Remove avatar.png" too.
    within(gallery_field) { click_button "Remove avatar.png" }

    expect(gallery_field).to have_no_css("figure.govuk-attachment")
    expect(announcements_region(gallery_field)).to have_text("avatar.png removed")
    expect(status_region(gallery_field)).to have_text("No file chosen")

    click_button "Continue"

    expect(page).to have_current_path(profile_path(profile))
    expect(profile.reload.gallery).not_to be_attached
  end

  # Browsers replace the FileList on re-selection, so previews of files no
  # longer in the input must not linger (they would suggest files that won't
  # submit).
  it "replaces stale previews when the selection changes" do
    visit edit_profile_path(profile)

    choose_gallery_file("avatar.png")

    expect(gallery_field).to have_css("figure.govuk-attachment", count: 1)

    choose_gallery_file("cv.pdf")

    expect(gallery_field).to have_css("figure.govuk-attachment .filename", text: "cv.pdf")
    expect(gallery_field).to have_no_css("figure.govuk-attachment .filename", text: "avatar.png")
    expect(status_region(gallery_field)).to have_text("1 file chosen")
  end
end
