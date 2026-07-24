# frozen_string_literal: true

require "rails_helper"

# The upload button's status region describes the field's contents using
# govuk-frontend's FileUpload i18n strings: "No file chosen" when the field
# is empty, else the count of attachment figures plus any files held in the
# FileList ("2 files chosen"). The region carries only this state — event
# announcements (e.g. removals) go to the assertive announcements region.
RSpec.describe "Attachment field status", :aggregate_failures do
  include AttachmentFieldHelpers

  let(:profile) { create(:profile) }

  it "reports an empty field as having no file chosen" do
    visit edit_profile_path(profile)

    expect(status_region(gallery_field)).to have_text("No file chosen")
  end

  it "reports an empty has_one field as having no file chosen" do
    visit edit_profile_path(profile)

    expect(status_region(cv_field)).to have_text("No file chosen")
  end

  it "counts existing attachments on load" do
    attach_gallery_files
    visit edit_profile_path(profile)

    expect(status_region(gallery_field)).to have_text("2 files chosen")
  end

  it "counts a newly uploaded file" do
    visit edit_profile_path(profile)

    choose_gallery_file("avatar.png")

    expect(gallery_field).to have_css("figure.govuk-attachment[data-state=upload-successful]", wait: 10)
    expect(status_region(gallery_field)).to have_text("1 file chosen")
  end

  it "recounts after a removal" do
    attach_gallery_files
    visit edit_profile_path(profile)

    click_button "Remove first.png"

    expect(status_region(gallery_field)).to have_text("1 file chosen")
  end

  def attach_gallery_files
    %w[first.png second.png].each do |filename|
      profile.gallery.attach(io: File.open(file_fixture("avatar.png")), filename:, content_type: "image/png")
    end
  end
end
