# frozen_string_literal: true

require "rails_helper"

# Rendering an attachment field for an object carrying pending attachment
# changes — a multipart upload assigned but never saved, as on an
# invalid-submit re-render. A pending blob has no bytes in storage until the
# record saves, so the field owns making it renderable:
#
#   * an unpersisted blob is persisted (bytes uploaded, record saved) before
#     its preview renders, so its signed id round-trips like a direct upload
#   * a blob that is already persisted is left alone — never re-uploaded
#   * a blob whose persist fails is dropped — no figure — rather than
#     failing the whole render; the file input remains for re-choosing
RSpec.describe "govuk attachment fields with pending attachment changes" do
  let(:builder) { GOVUKDesignSystemFormBuilder::FormBuilder.new(:profile, profile, helper, {}) }
  let(:profile) { create(:profile) }

  def render_avatar_field
    Capybara.string(builder.govuk_image_field(:avatar).to_s)
  end

  context "with an unpersisted multipart upload" do
    before do
      profile.avatar = Rack::Test::UploadedFile.new(file_fixture("avatar.png"), "image/png")
    end

    def pending_blob
      profile.attachment_changes["avatar"].blob
    end

    it "persists the pending blob" do
      expect { render_avatar_field }.to change(pending_blob, :persisted?).to(true)
    end

    it "uploads the bytes" do
      render_avatar_field

      expect(pending_blob.service.exist?(pending_blob.key)).to be(true)
    end

    it "renders the preview from the uploaded bytes" do
      html = render_avatar_field

      expect(html.find("figure.govuk-attachment img")[:src]).to be_present
    end

    it "renders the persisted blob's signed id as the keep option" do
      html = render_avatar_field

      expect(html.find("figure.govuk-attachment select option[selected]", visible: :all).value)
        .to eq(pending_blob.signed_id)
    end
  end

  context "with a pending change whose blob is already persisted" do
    # A direct upload arrives as a signed id: the blob already exists with
    # bytes. Non-representable content keeps variant processing out of the
    # render, so any upload call could only come from a wrongful re-persist.
    let(:blob) do
      ActiveStorage::Blob.create_and_upload!(
        io:           StringIO.new("plain text"),
        filename:     "notes.txt",
        content_type: "text/plain",
      )
    end

    before { profile.avatar = blob.signed_id }

    it "does not upload again" do
      allow(ActiveStorage::Blob.service).to receive(:upload)

      render_avatar_field

      expect(ActiveStorage::Blob.service).not_to have_received(:upload)
    end

    it "renders the figure" do
      expect(render_avatar_field).to have_css("figure.govuk-attachment .filename", text: "notes.txt")
    end
  end

  context "when persisting the pending blob fails" do
    before do
      profile.avatar = Rack::Test::UploadedFile.new(file_fixture("avatar.png"), "image/png")
      allow(ActiveStorage::Blob.service).to receive(:upload).and_raise(ActiveStorage::IntegrityError)
    end

    it "drops the figure rather than failing the render" do
      expect(render_avatar_field).to have_no_css("figure.govuk-attachment")
    end

    it "still renders the file input so the user can re-choose" do
      expect(render_avatar_field).to have_field("profile[avatar]", type: :file, visible: :all)
    end

    it "leaves no half-persisted blob behind" do
      render_avatar_field

      expect(profile.attachment_changes["avatar"].blob).not_to be_persisted
    end

    # ActiveStorage's log subscriber only reports successful service calls
    # (it ignores the exception payload), so once the field swallows the
    # error, this warning is the only record that a user's file was dropped.
    it "logs the dropped upload" do
      allow(Rails.logger).to receive(:warn)

      render_avatar_field

      expect(Rails.logger).to have_received(:warn)
                                .with(include("avatar").and(include("ActiveStorage::IntegrityError")))
    end
  end

  context "with a mixed gallery of a persisted signed id and a multipart upload" do
    let(:persisted) do
      ActiveStorage::Blob.create_and_upload!(
        io:           File.open(file_fixture("avatar.png")),
        filename:     "persisted.png",
        content_type: "image/png",
      )
    end

    before do
      profile.gallery = [
        persisted.signed_id,
        Rack::Test::UploadedFile.new(file_fixture("avatar.png").open, "image/png",
                                     original_filename: "fresh.png"),
      ]
    end

    def render_gallery_field
      Capybara.string(builder.govuk_image_field(:gallery).to_s)
    end

    it "persists every pending blob in the change" do
      render_gallery_field

      expect(profile.attachment_changes["gallery"].blobs).to all(be_persisted)
    end

    it "renders a figure for each entry" do
      html = render_gallery_field

      expect(html.all("figure.govuk-attachment .filename").map(&:text))
        .to contain_exactly("persisted.png", "fresh.png")
    end
  end
end
