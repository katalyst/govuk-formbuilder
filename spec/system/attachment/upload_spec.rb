# frozen_string_literal: true

require "rails_helper"

# Direct-upload lifecycle for the attachment field, exercised through the
# gallery (has_many_attached) field on the profile form.
#
# The figure's `data-state` attribute is the observable surface, so the
# implementation is free to change markup/classes without breaking the
# behavioural contract:
#
#   * choosing a file immediately inserts a preview figure in an
#     `uploading` state
#   * on direct-upload success the figure reaches `upload-successful` and
#     its select's first option carries the new blob's signed id
#   * on failure the figure reaches `upload-failed` with a human-readable
#     message and retry/remove; a failed figure never submits a signed id
#
RSpec.describe "Async file upload", :aggregate_failures do
  include AttachmentFieldHelpers
  include DirectUploadHelpers

  let(:profile) { create(:profile) }

  it "previews the chosen file immediately, in an uploading state" do
    block_direct_uploads
    visit edit_profile_path(profile)

    expect(gallery_field).to have_field("profile[gallery][]", type: :file, visible: :all)
    expect(gallery_field).to have_no_css("figure.govuk-attachment")

    choose_gallery_file("avatar.png")

    expect(gallery_field).to have_css("figure.govuk-attachment[data-state=uploading] .filename", text: "avatar.png")
    expect(gallery_field).to have_css("figure.govuk-attachment[data-state=uploading] progress")

    release_direct_uploads

    expect(gallery_field).to have_css("figure.govuk-attachment[data-state=upload-successful]", wait: 10)

    # The progress bar is removed and the caption's live region announces the
    # result, so screen readers hear which file finished.
    expect(gallery_field).to have_no_css("figure.govuk-attachment progress")
    expect(gallery_field).to have_css("figure.govuk-attachment figcaption .status", text: /uploaded/i)
  end

  it "names the progress bar after the file it reports" do
    block_direct_uploads
    visit edit_profile_path(profile)

    choose_gallery_file("avatar.png")

    progress   = gallery_field.find("figure.govuk-attachment progress")
    referenced = progress["aria-labelledby"].to_s.split.map { |id| page.find(id: id, visible: :all).text }

    expect(referenced.join(" ")).to eq("avatar.png")

    release_direct_uploads
  end

  it "reaches upload-successful with the blob's signed id in the select" do
    visit edit_profile_path(profile)

    choose_gallery_file("avatar.png")

    # Generous wait: a real XHR to the direct-uploads endpoint plus a blob PUT.
    expect(gallery_field).to have_css("figure.govuk-attachment[data-state=upload-successful]", wait: 10)

    signed_id = gallery_field.find(
      "figure.govuk-attachment select[name='profile[gallery][]'] option:first-of-type",
      visible: :all,
    ).value
    expect(ActiveStorage::Blob.find_signed(signed_id)&.filename&.to_s).to eq("avatar.png")
  end

  # The figure claims the file from the input's FileList when its upload
  # starts, so submitting must attach the blob once — not again as multipart.
  it "attaches an uploaded file exactly once on submit" do
    visit edit_profile_path(profile)

    choose_gallery_file("avatar.png")

    expect(gallery_field).to have_css("figure.govuk-attachment[data-state=upload-successful]", wait: 10)

    click_button "Continue"

    expect(page).to have_current_path(profile_path(profile))
    expect(profile.reload.gallery.blobs.map { |blob| blob.filename.to_s }).to eq(%w[avatar.png])
  end

  it "reaches upload-failed with a human-readable message, and never submits a signed id" do
    break_direct_uploads
    visit edit_profile_path(profile)

    # Record alert calls: ActiveStorage's dispatchError falls back to window.alert
    page.execute_script("window.alertCalls = []; window.alert = (message) => window.alertCalls.push(message)")

    choose_gallery_file("avatar.png")

    figure = gallery_field.find("figure.govuk-attachment[data-state=upload-failed]", wait: 10)

    # A friendly message, not DirectUpload's raw error/alert.
    expect(figure.text).to include("Upload failed")
    expect(figure.text).not_to include("Error")
    expect(page.evaluate_script("window.alertCalls")).to eq([])

    # The user can recover from the error: remove, or retry the upload with
    # the file the figure still holds.
    expect(figure).to have_css("button[aria-label*='Remove']")
    expect(figure).to have_css("button[type=button][aria-label='Try again avatar.png']", text: "Try again")

    # Both figure controls follow govuk-frontend's button conventions (the
    # password toggle's markup shape).
    expect(figure).to have_button(class: %w[govuk-button govuk-button--secondary govuk-attachment__retry])

    click_button "Continue"

    # Submitting without clearing the error does not save the file
    expect(page).to have_current_path(profile_path(profile))
    expect(profile.reload.gallery).not_to be_attached
  end

  it "retries a failed upload with the file the figure holds" do
    block_direct_uploads
    visit edit_profile_path(profile)

    choose_gallery_file("avatar.png")
    release_direct_uploads(:internal_server_error)

    figure = gallery_field.find("figure.govuk-attachment[data-state=upload-failed]", wait: 10)

    click_button "Try again"

    # Retry re-enters the standard uploading lifecycle; the retry control
    # leaves with the failed state.
    expect(gallery_field).to have_css("figure.govuk-attachment[data-state=uploading] progress")
    expect(figure).to have_no_button("Try again")

    release_direct_uploads(:ok)

    expect(gallery_field).to have_css("figure.govuk-attachment[data-state=upload-successful]", wait: 10)

    signed_id = gallery_field.find(
      "figure.govuk-attachment select[name='profile[gallery][]'] option:first-of-type",
      visible: :all,
    ).value
    expect(ActiveStorage::Blob.find_signed(signed_id)&.filename&.to_s).to eq("avatar.png")
  end

  it "moves focus to the figure's remove button when retry starts" do
    block_direct_uploads
    visit edit_profile_path(profile)

    choose_gallery_file("avatar.png")
    release_direct_uploads(:internal_server_error)

    gallery_field.find("figure.govuk-attachment[data-state=upload-failed]", wait: 10)

    click_button "Try again"

    # Retrying removes the retry control from under the user; focus moves to
    # the figure's remove button — the figure's only control while uploading
    # — rather than dropping to <body>.
    expect(
      page.evaluate_script("document.activeElement.getAttribute('aria-label')"),
    ).to eq("Remove avatar.png")

    release_direct_uploads(:ok)
  end

  it "offers a single retry control however many attempts fail" do
    block_direct_uploads
    visit edit_profile_path(profile)

    choose_gallery_file("avatar.png")
    release_direct_uploads(:internal_server_error)

    gallery_field.find("figure.govuk-attachment[data-state=upload-failed]", wait: 10)

    click_button "Try again"
    release_direct_uploads(:internal_server_error)

    expect(gallery_field).to have_css("figure.govuk-attachment[data-state=upload-failed]", wait: 10)
    expect(gallery_field).to have_css("button[type=button][aria-label='Try again avatar.png']", count: 1)
  end
end
