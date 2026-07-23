# frozen_string_literal: true

require "rails_helper"

# Turbo morph resilience for the attachment field, exercised through the
# avatar (has_one_attached) field.
#
# The pseudo upload button, its status region, and the announcements region
# are injected by the file-upload controller and are never server-rendered, so
# a Turbo morph refresh — here the re-render of a failed update (the layout
# opts into `turbo-refresh-method: morph`) — always strips them: the server
# response contains none of that UI. Depending on whether the surrounding
# structure changed (e.g. the error summary appearing), idiomorph either
# destroys and recreates the drop zone (Stimulus disconnect/connect fires
# instead of any morph event) or patches it in place (morph events, no
# lifecycle events). The morph also strips the JS-set
# `govuk-frontend-supported` class from `<body>`, reverting the CSS gate to
# the no-JS presentation page-wide. Whatever the path, the field must come
# back working: supported marker restored, injected UI rebuilt, count
# matching the server-rendered figures.
RSpec.describe "Attachment field surviving a Turbo morph", :aggregate_failures do
  include AttachmentFieldHelpers

  # Attached under a distinct name so the replacement uploaded mid-test is
  # distinguishable from it.
  let(:profile) do
    create(:profile).tap do |p|
      p.avatar.attach(io: File.open(file_fixture("avatar.png")), filename: "old-avatar.png", content_type: "image/png")
    end
  end

  it "re-enhances the field after failed updates morph the page" do
    visit edit_profile_path(profile)

    # Enhanced on load: the injected button reports the one attached file.
    expect(avatar_field).to have_css("button [aria-live]", text: "1 file chosen")

    # First failed submit — the recreate path, not yet a morph-event test:
    # inserting the error summary shifts the form groups onto each other's
    # nodes, so idiomorph destroys and recreates the drop zone and
    # disconnect/connect fires instead of any morph event. The field must be
    # rebuilt from the degraded server markup.
    fill_in "Name", with: ""
    click_button "Continue"

    expect(page).to have_css(".govuk-error-summary")

    # The attachment comes back as a server-rendered figure whose preview
    # points at the blob on the server (not a client-side data: URL).
    expect(avatar_field).to have_css("figure.govuk-attachment .filename", exact_text: "old-avatar.png")
    expect(avatar_field).to have_css("figure.govuk-attachment img[src*='/rails/active_storage']")
    expect(avatar_field).to have_css("button [aria-live]", text: "1 file chosen")

    # Upload a replacement so the next morph reconciles a field with real
    # client-side changes — a client-inserted figure carrying the new blob's
    # signed id — not just a re-render of what the server already knows.
    choose_avatar_file("avatar.png")

    expect(avatar_field).to have_css("figure.govuk-attachment[data-state=upload-successful]", wait: 10)

    # Second failed submit — the patch path, the morph case proper. The
    # summary already exists so the structures align, and the drop zone is
    # patched in place: morph events fire but no Stimulus lifecycle events
    # do, so re-enhancement cannot come from connect(). The name is still
    # blank, so the submit fails again, but the replacement's signed id
    # round-trips: the server re-renders it as the field's server figure.
    click_button "Continue"

    expect(page).to have_css(".govuk-error-summary")
    expect(avatar_field).to have_css("figure.govuk-attachment .filename", exact_text: "avatar.png")
    expect(avatar_field).to have_css("figure.govuk-attachment img[src*='/rails/active_storage']")
    expect(avatar_field).to have_css("button [aria-live]", text: "1 file chosen")
  end
end
