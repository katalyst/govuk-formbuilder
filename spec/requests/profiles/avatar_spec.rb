# frozen_string_literal: true

require "rails_helper"

# Updating Profile#avatar (has_one_attached, required — cv is the optional
# counterpart) through the controller: the scalar counterpart to
# gallery_spec.rb. The keep/remove select submits the blob's signed id to
# retain; blank fails the presence validation rather than detaching.
RSpec.describe "Updating a profile's avatar" do
  include AttachmentRequestHelpers

  let(:profile) { create(:profile) }

  it "keeps the attachment when its signed id is submitted" do
    patch profile_path(profile), params: { profile: { avatar: profile.avatar.signed_id } }

    expect(profile.reload.avatar).to be_attached
  end

  it "rejects removal: blank fails the presence validation and keeps the file" do
    patch profile_path(profile), params: { profile: { avatar: "" } }

    aggregate_failures do
      expect(response).to have_http_status(:unprocessable_content)
      expect(profile.reload.avatar).to be_attached
    end
  end

  it "replaces when a different blob's signed id is submitted" do
    blob = uploaded_blob(filename: "replacement.png")

    patch profile_path(profile), params: { profile: { avatar: blob.signed_id } }

    expect(profile.reload.avatar.blob).to eq(blob)
  end

  # A submit that fails validation re-renders the submitted signed id as a
  # server figure with its keep option preserved — for a scalar field the
  # last-submitted blob is the whole assignment, so a replacement supersedes
  # the persisted avatar in the re-render.
  describe "round-trip on an invalid submit" do
    let(:uploaded) { uploaded_blob(filename: "updated.png") }

    def submit_invalid
      patch profile_path(profile),
            params: { profile: { name: "", email: "ada@example.com", avatar: uploaded.signed_id } }
    end

    context "when the fresh upload replaces the persisted avatar" do
      before { submit_invalid }

      it "re-renders the replacement" do
        expect(figure_for("updated.png")).to be_present
      end

      it "does not re-render the superseded avatar" do
        expect(figure_for("avatar.png")).to be_nil
      end
    end
  end
end
