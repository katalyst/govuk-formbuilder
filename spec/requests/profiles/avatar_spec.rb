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

  it "rejects removal: blank fails the presence validation" do
    patch profile_path(profile), params: { profile: { avatar: "" } }

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "rejects removal: blank keeps the stored file" do
    patch profile_path(profile), params: { profile: { avatar: "" } }

    expect(profile.reload.avatar).to be_attached
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

  # Without JavaScript a file arrives as a real multipart upload; its bytes
  # reach storage only on save, which the failing validation prevents, and
  # browsers never repopulate file inputs — left alone, the upload would be
  # lost. The field persists pending uploads when it renders, so the
  # re-render turns them into figures whose signed ids round-trip like any
  # direct upload: the user never loses the file, and the submitted set
  # stays the truth (the superseded avatar is not resurrected, as with
  # signed-id replacement above).
  describe "multipart upload beside a failing validation" do
    before do
      patch profile_path(profile),
            params: { profile: { name: "", email: "ada@example.com",
                                 avatar: multipart_upload("updated.png") } }
    end

    it "responds unprocessable rather than failing to render" do
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "re-renders the upload as a figure" do
      expect(figure_for("updated.png")).to be_present
    end

    it "preserves the upload as a signed id that round-trips" do
      signed_id = kept_signed_id(figure_for("updated.png"))

      expect(ActiveStorage::Blob.find_signed(signed_id)&.filename&.to_s).to eq("updated.png")
    end

    it "does not re-render the superseded avatar" do
      expect(figure_for("avatar.png")).to be_nil
    end

    it "leaves the stored avatar untouched (nothing was attached)" do
      expect(profile.reload.avatar.filename.to_s).to eq("avatar.png")
    end
  end

  # The GOV.UK error contract for an attachment attribute: the message
  # renders inside the field's own form group, above the input, and the
  # error summary links to the field.
  describe "error placement on a blank required avatar" do
    before { patch profile_path(profile), params: { profile: { avatar: "" } } }

    def document
      Nokogiri::HTML(response.body)
    end

    def avatar_form_group
      document.css("div.govuk-form-group").find do |group|
        group.at_css("input[name='profile[avatar]']")
      end
    end

    it "marks the avatar field's form group as errored" do
      expect(avatar_form_group["class"]).to include("govuk-form-group--error")
    end

    it "renders the validation message inside the form group" do
      expect(avatar_form_group.at_css("p.govuk-error-message").text).to match(/blank/i)
    end

    it "renders the message above the input" do
      first = avatar_form_group.css("p.govuk-error-message, input[name='profile[avatar]']").first

      expect(first.name).to eq("p")
    end

    it "links the error summary entry to the avatar field" do
      input = document.at_css("input[type=file][name='profile[avatar]']")

      expect(document.at_css(".govuk-error-summary a[href='##{input[:id]}']").text).to match(/blank/i)
    end
  end
end
