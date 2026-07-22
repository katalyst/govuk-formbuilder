# frozen_string_literal: true

require "rails_helper"

# Updating Profile#cv (has_one_attached, optional — avatar is the required
# counterpart). Optional scalar semantics live here: blank detaches, and a
# fresh upload round-trips on a profile that has nothing attached yet.
RSpec.describe "Updating a profile's cv" do
  include AttachmentRequestHelpers

  let(:profile) { create(:profile) }

  def attach_cv
    profile.cv.attach(io: File.open(file_fixture("cv.pdf")), filename: "cv.pdf", content_type: "application/pdf")
  end

  it "attaches an uploaded blob's signed id" do
    blob = uploaded_blob(filename: "new-cv.png")

    patch profile_path(profile), params: { profile: { cv: blob.signed_id } }

    expect(profile.reload.cv.blob).to eq(blob)
  end

  it "detaches when blank is submitted" do
    attach_cv

    patch profile_path(profile), params: { profile: { cv: "" } }

    expect(profile.reload.cv).not_to be_attached
  end

  describe "round-trip on an invalid submit" do
    let(:uploaded) { uploaded_blob(filename: "new-cv.png") }

    # A fresh upload arriving on a profile with no cv — the empty-scalar
    # round-trip an always-attached avatar can't express.
    before do
      patch profile_path(profile),
            params: { profile: { name: "", email: "ada@example.com", cv: uploaded.signed_id } }
    end

    it "re-renders the just-uploaded blob as a figure" do
      expect(figure_for("new-cv.png")).to be_present
    end

    it "preserves its signed id as the keep option" do
      expect(kept_signed_id(figure_for("new-cv.png"))).to eq(uploaded.signed_id)
    end
  end
end
