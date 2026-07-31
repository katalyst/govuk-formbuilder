# frozen_string_literal: true

require "rails_helper"

# End-to-end round-trip of a direct-uploaded attachment across an invalid
# submit, exercised through the gallery (has_many_attached) field.
#
# A file is direct-uploaded with JavaScript (its figure reaches
# upload-successful, carrying the new blob's signed id), then the form is made
# invalid and submitted. The server re-renders the form with the just-uploaded
# blob as a plain server-rendered figure — no upload state, its signed id
# preserved so it still submits — so the user never re-uploads. The failure
# also renders in the standard GOV.UK error summary.
RSpec.describe "Attachment round-trip across an invalid submit", :aggregate_failures do
  include AttachmentFieldHelpers

  let(:profile) { create(:profile) }

  it "re-renders the uploaded blob as a server figure and shows the error summary" do
    visit edit_profile_path(profile)

    choose_gallery_file("avatar.png")

    expect(gallery_field).to have_css("figure.govuk-attachment[data-state=upload-successful]", wait: 10)

    signed_id = gallery_field.find(
      "figure.govuk-attachment select[name='profile[gallery][]'] option:first-of-type",
      visible: :all,
    ).value

    # Invalidate the form so the submit fails and re-renders.
    fill_in "Name", with: ""
    click_button "Continue"

    # The failed submit re-renders the form in place (Turbo keeps the edit URL).
    expect(page).to have_css(".govuk-error-summary")

    # The uploaded blob comes back as a server-rendered figure: it names the
    # file and carries no upload state (it is not re-uploaded), and its keep
    # option still holds the signed id so it submits unchanged.
    expect(gallery_field).to have_css("figure.govuk-attachment .filename", text: "avatar.png")
    expect(gallery_field).to have_no_css("figure.govuk-attachment[data-state]")
    expect(gallery_field).to have_css(
      "figure.govuk-attachment select[name='profile[gallery][]'] option[value='#{signed_id}']",
      visible: :all,
    )

    # The preserved figure really does submit: fix the form and the blob attaches.
    fill_in "Name", with: "Ada Lovelace"
    click_button "Continue"

    expect(page).to have_current_path(profile_path(profile))
    expect(profile.reload.gallery.blobs.map { |blob| blob.filename.to_s }).to eq(%w[avatar.png])
  end
end
