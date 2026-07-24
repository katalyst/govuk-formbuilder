# frozen_string_literal: true

require "rails_helper"

# Replacing a has_one_attached file with JavaScript, exercised through the
# avatar field on the profile form.
#
# Every figure's select posts the same scalar param (profile[avatar]) and the
# last one wins, so uploading a replacement appends a new figure rather than
# editing the old one: CSS hides every figure but the last, and the original
# stays in the DOM so removing the replacement reveals it again — reverting
# is free.
RSpec.describe "Replacing an attachment", :aggregate_failures do
  include AttachmentFieldHelpers
  include DirectUploadHelpers

  let(:profile) do
    create(:profile).tap do |p|
      p.avatar.attach(io: File.open(file_fixture("avatar.png")), filename: "old-avatar.png", content_type: "image/png")
    end
  end

  before do
    Capybara.enable_aria_label = true
  end

  after do
    Capybara.enable_aria_label = false
  end

  it "supersedes the existing figure, leaving one visible" do
    visit edit_profile_path(profile)

    choose_avatar_file("avatar.png")

    expect(avatar_field).to have_css("figure.govuk-attachment[data-state=upload-successful]", wait: 10)

    # Both figures stay in the DOM (the original is what makes revert
    # possible), but only the replacement is shown.
    expect(avatar_field).to have_css("figure.govuk-attachment", count: 2, visible: :all)
    expect(avatar_field).to have_css("figure.govuk-attachment", count: 1)
    expect(avatar_field).to have_css("figure.govuk-attachment .filename", exact_text: "avatar.png")
    expect(avatar_field).to have_css("figure.govuk-attachment", text: "old-avatar.png", visible: :hidden)
  end

  it "saves the replacement" do
    visit edit_profile_path(profile)

    choose_avatar_file("avatar.png")

    expect(avatar_field).to have_css("figure.govuk-attachment[data-state=upload-successful]", wait: 10)

    click_button "Continue"

    expect(page).to have_current_path(profile_path(profile))
    expect(profile.reload.avatar.filename.to_s).to eq("avatar.png")
  end

  it "clears optional inputs when a replacement is submitted during upload" do
    profile.cv.attach(io: File.open(file_fixture("cv.pdf")), filename: "cv.pdf", content_type: "application/pdf")
    block_direct_uploads
    visit edit_profile_path(profile)

    choose_cv_file("cv.pdf")

    expect(cv_field).to have_css("figure.govuk-attachment[data-state=uploading]")

    click_button "Continue"

    expect(page).to have_current_path(profile_path(profile))
    expect(profile.reload.cv).not_to be_attached
  end

  it "keeps stored files with errors when a replacement is submitted during upload" do
    block_direct_uploads
    visit edit_profile_path(profile)

    choose_avatar_file("avatar.png")

    expect(avatar_field).to have_css("figure.govuk-attachment[data-state=uploading]")

    click_button "Continue"

    expect(page).to have_css(
      ".govuk-form-group--error:has(input[name='profile[avatar]']) p.govuk-error-message",
      text: /blank/i,
    )
    expect(profile.reload.avatar.filename.to_s).to eq("old-avatar.png")
  end

  it "reverts to the original when the replacement is removed" do
    visit edit_profile_path(profile)

    choose_avatar_file("avatar.png")

    expect(avatar_field).to have_css("figure.govuk-attachment[data-state=upload-successful]", wait: 10)

    click_button "Remove avatar.png"

    expect(avatar_field).to have_css("figure.govuk-attachment .filename", exact_text: "old-avatar.png")

    click_button "Continue"

    expect(page).to have_current_path(profile_path(profile))
    expect(profile.reload.avatar.filename.to_s).to eq("old-avatar.png")
  end
end
