# frozen_string_literal: true

# :markup: markdown

require "rails_helper"

# Server-rendered markup for govuk_attachment_field.
#
# Tests:
# * Profile's has_one_attached :avatar: (required)
#   one figure per attached blob (preview, caption, actions)
# * Profile's has_many_attached :gallery: (optional)
#   multiple figures, one per attached blob (preview, caption, actions)
# * Profile's has_one_attached :cv: (optional)
#   one figure per attached blob (caption, actions)
# * Round-tripping multipart form inputs
RSpec.describe GOVUKDesignSystemFormBuilder::FormBuilder do
  let(:builder) { described_class.new(:profile, profile, helper, {}) }
  let(:profile) { create(:profile) }

  def govuk_attachment_field(...)
    Capybara.string(builder.govuk_attachment_field(...).to_s)
  end

  describe "#govuk_attachment_field (avatar / single / required)" do
    subject(:html) { govuk_attachment_field(:avatar) }

    let(:blob) { profile.avatar.blob }

    context "with no attachment" do
      let(:profile) { Profile.new }

      it "renders no attachment figures" do
        expect(html).to have_no_css("figure.govuk-attachment")
      end

      it "renders a single file input inside the wrapper" do
        expect(html).to have_css(".govuk-file-upload-wrapper input[type=file]", count: 1, visible: :all)
      end

      it "does not mark the file input as multiple" do
        expect(html).to have_no_css("input[type=file][multiple]", visible: :all)
      end

      # Exclusivity invariant: initAll enhances data-module="govuk-file-upload"
      # with govuk-frontend's own FileUpload, so an attachment field emitting it
      # would have two implementations fighting over one input.
      it "never emits govuk-frontend's file-upload data-module" do
        expect(html).to have_no_css("[data-module='govuk-file-upload']", visible: :all)
      end
    end

    # The label, caption, hint and form_group configuration must render
    # through the element rather than being dropped; the image and document
    # wrappers forward these options here and rely on them being consumed.
    context "with configuration options" do
      it "renders the hint" do
        html = govuk_attachment_field(:avatar, hint: { text: "Max 5MB" })

        expect(html).to have_css(".govuk-hint", text: "Max 5MB")
      end

      it "describes the input by the hint" do
        html    = govuk_attachment_field(:avatar, hint: { text: "Max 5MB" })
        hint_id = html.find(".govuk-hint", visible: :all)[:id]

        expect(html.find("input[type=file]", visible: :all)["aria-describedby"]).to eq(hint_id)
      end

      it "renders the supplied label text" do
        html = govuk_attachment_field(:avatar, label: { text: "Your photo" })

        expect(html).to have_css("label", text: "Your photo")
      end

      it "renders the supplied caption" do
        html = govuk_attachment_field(:avatar, caption: { text: "Step 1" })

        expect(html).to have_css(".govuk-caption-m", text: "Step 1")
      end

      it "applies form_group options" do
        html = govuk_attachment_field(:avatar, form_group: { class: "extra-group" })

        expect(html).to have_css(".govuk-form-group.extra-group")
      end
    end

    context "with an attached image" do
      it "renders one figure with preview, caption, and actions, in order" do
        expect(html).to have_css("figure.govuk-attachment > img + figcaption + div.actions", count: 1, visible: :all)
      end

      it "groups the select and remove button in the actions container" do
        expect(html).to have_css("figure.govuk-attachment .actions > select + button", visible: :all)
      end

      it "does not process the preview variant at render time" do
        expect { html }.not_to change(ActiveStorage::VariantRecord, :count)
      end

      it "captions the figure with the filename" do
        expect(html).to have_css("figure.govuk-attachment figcaption .filename", text: "avatar.png")
      end

      it "captions the figure with the human file size" do
        expect(html).to have_css("figure.govuk-attachment figcaption .size", text: /\A[\d.]+ (Bytes|KB|MB)\z/)
      end

      it "selects the current file, labelled with its filename" do
        expect(html).to have_css(
          "figure.govuk-attachment select option[selected][value='#{blob.signed_id}']",
          text:    "avatar.png",
          visible: :all,
        )
      end

      it "offers a remove option with a blank value naming the file" do
        expect(html).to have_css(
          "figure.govuk-attachment select option[value='']",
          text:    "Remove avatar.png",
          visible: :all,
        )
      end

      it "inputs a hidden input to track removes" do
        expect(html).to have_css(".govuk-file-upload-wrapper input[type=hidden]", count: 1, visible: :all)
      end

      it "renders the blank keeper first, before the other input(s)" do
        types = html.all("[name='profile[avatar]']", visible: :all).map do |node|
          "#{node.tag_name}[type=#{node['type']}]"
        end

        expect(types).to eq(%w[input[type=hidden] select[type=] input[type=file]])
      end

      it "names the select for scalar assignment" do
        select = html.find("figure.govuk-attachment select", visible: :all)

        expect(select["name"]).to eq("profile[avatar]")
      end

      it "gives the select a unique per-blob id" do
        select = html.find("figure.govuk-attachment select", visible: :all)

        expect(select["id"]).to eq(builder.field_id(:avatar, :attachment, blob.id, :input))
      end

      # Hiding the select is CSS-gated on .govuk-frontend-supported so that
      # without JavaScript it stays the visible control.
      it "does not hide the select in markup" do
        expect(html).to have_no_css("figure.govuk-attachment select.govuk-visually-hidden", visible: :all)
      end

      it "renders a remove button wired to the attachment controller" do
        expect(html).to have_css("figure.govuk-attachment .actions button[data-action='govuk-attachment#destroy']")
      end

      it "labels the remove button with the filename" do
        button = html.find("figure.govuk-attachment .actions button")

        expect(button["aria-label"]).to eq("Remove avatar.png")
      end

      it "stops the remove button from submitting the form" do
        button = html.find("figure.govuk-attachment .actions button")

        expect(button["type"]).to eq("button")
      end

      it "hides the preview image from assistive technology" do
        expect(html.find("figure.govuk-attachment img")["alt"]).to eq("")
      end

      it "labels the figure with its caption" do
        figure = html.find("figure.govuk-attachment")

        expect(figure["aria-labelledby"]).to eq(builder.field_id(:avatar, :attachment, blob.id, :caption))
      end

      it "makes the caption a polite live region so status changes are announced" do
        expect(html.find("figure.govuk-attachment figcaption")["aria-live"]).to eq("polite")
      end

      it "announces the whole caption atomically, so announcements name the file" do
        expect(html.find("figure.govuk-attachment figcaption")["aria-atomic"]).to eq("true")
      end

      it "reserves an empty status span in the caption for upload announcements" do
        expect(html.find("figure.govuk-attachment figcaption .status").text).to eq("")
      end

      it "gives the select an accessible name that includes the filename" do
        select      = html.find("figure.govuk-attachment select", visible: :all)
        referenced  = select["aria-labelledby"].to_s.split.flat_map { |id| html.all("[id='#{id}']").map(&:text) }
        label_texts = html.all("label[for='#{select['id']}']", visible: :all).map(&:text)

        expect([select["aria-label"], *referenced, *label_texts].compact.join(" ")).to include("avatar.png")
      end
    end

    # The preview URL is lazy — the variant is processed when the browser
    # requests it, so rendering the form never touches the blob's bytes and
    # a blob that can't be processed costs a broken image, not an error.
    context "with an attached image whose bytes are missing" do
      before { blob.service.delete(blob.key) }

      it "renders the figure" do
        expect(html).to have_css("figure.govuk-attachment .filename", text: "avatar.png")
      end

      it "renders the preview, leaving the failure to the image request" do
        expect(html.find("figure.govuk-attachment img")[:src]).to be_present
      end

      it "keeps the blob's signed id as the keep option" do
        expect(html.find("figure.govuk-attachment select option[selected]", visible: :all).value)
          .to eq(blob.signed_id)
      end
    end

    context "with a non-image attachment" do
      before do
        profile.avatar.attach(
          io:           StringIO.new("not an image"),
          filename:     "notes.txt",
          content_type: "text/plain",
        )
      end

      it "renders the figure with caption and actions adjacent" do
        expect(html).to have_css("figure.govuk-attachment > figcaption + div.actions", visible: :all)
      end

      it "omits the preview image" do
        expect(html).to have_no_css("figure.govuk-attachment img")
      end
    end

    describe "#direct_upload_url" do
      it "adds data-direct-upload-url by default" do
        input = html.find("input[type=file]", visible: :all)

        expect(input["data-direct-upload-url"]).to eq(helper.rails_direct_uploads_url)
      end

      it "respects direct_upload: false" do
        html = govuk_attachment_field(:avatar, direct_upload: false)

        expect(html).to have_css("input[type=file]:not([data-direct-upload-url])", visible: :all)
      end

      it "still renders the attachment figure when direct_upload is false" do
        html = govuk_attachment_field(:avatar, direct_upload: false)

        expect(html).to have_css("figure.govuk-attachment > img + figcaption + div.actions", visible: :all)
      end

      it "uses direct_upload_url when provided" do
        html  = govuk_attachment_field(:avatar, direct_upload_url: "/override")
        input = html.find("input[type=file]", visible: :all)

        expect(input["data-direct-upload-url"]).to eq("/override")
      end

      it "uses direct_upload_url from form builder when overridden (i.e. Koi admin)" do
        builder.instance_eval do
          def direct_upload_url
            "/extend"
          end
        end

        input = html.find("input[type=file]", visible: :all)

        expect(input["data-direct-upload-url"]).to eq("/extend")
      end

      it "resolves direct-upload-url through main_app" do
        allow(helper).to receive(:respond_to?).and_call_original
        allow(helper).to receive(:respond_to?).with(:rails_direct_uploads_url).and_return(false)

        input = html.find("input[type=file]", visible: :all)

        expect(input["data-direct-upload-url"]).to eq(helper.main_app.rails_direct_uploads_url)
      end

      it "does not set data-direct-upload-url when no direct-upload route is available" do
        allow(helper).to receive(:respond_to?).and_call_original
        allow(helper).to receive(:respond_to?).with(:rails_direct_uploads_url).and_return(false)
        allow(helper).to receive(:main_app).and_return(Object.new)

        expect(html).to have_css("input[type=file]:not([data-direct-upload-url])", visible: :all)
      end
    end

    # ActiveStorage's representation route lives in the application's route
    # set, so an engine-mounted form must resolve the preview URL through
    # main_app — the same resolution direct_upload_url uses.
    describe "preview URL resolution" do
      let(:representation) { blob.representation(resize_and_pad: [100, 100, { crop: :centre }]) }

      it "renders the preview from the representation route" do
        expect(html.find("figure.govuk-attachment img")[:src])
          .to eq(helper.rails_representation_path(representation))
      end

      it "resolves the preview URL through main_app" do
        allow(helper).to receive(:respond_to?).and_call_original
        allow(helper).to receive(:respond_to?).with(:rails_representation_path).and_return(false)

        expect(html.find("figure.govuk-attachment img")[:src])
          .to eq(helper.main_app.rails_representation_path(representation))
      end

      it "renders no preview when no representation route is available" do
        allow(helper).to receive(:respond_to?).and_call_original
        allow(helper).to receive(:respond_to?).with(:rails_representation_path).and_return(false)
        allow(helper).to receive(:main_app).and_return(Object.new)

        expect(html).to have_no_css("figure.govuk-attachment img")
      end
    end

    context "with an unpersisted multipart upload" do
      before do
        profile.avatar = Rack::Test::UploadedFile.new(file_fixture("avatar.png"), "image/png")
      end

      def pending_blob
        profile.attachment_changes["avatar"].blob
      end

      it "persists the pending blob" do
        expect { html }.to change(pending_blob, :persisted?).to(true)
      end

      it "uploads the bytes" do
        html

        expect(pending_blob.service.exist?(pending_blob.key)).to be(true)
      end

      it "renders the preview from the uploaded bytes" do
        expect(html.find("figure.govuk-attachment img")[:src]).to be_present
      end

      it "renders the persisted blob's signed id as the keep option" do
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

        html

        expect(ActiveStorage::Blob.service).not_to have_received(:upload)
      end

      it "renders the figure" do
        expect(html).to have_css("figure.govuk-attachment .filename", text: "notes.txt")
      end
    end

    context "when persisting the pending blob fails" do
      before do
        profile.avatar = Rack::Test::UploadedFile.new(file_fixture("avatar.png"), "image/png")
        allow(ActiveStorage::Blob.service).to receive(:upload).and_raise(ActiveStorage::IntegrityError)
      end

      it "drops the figure rather than failing the render" do
        expect(html).to have_no_css("figure.govuk-attachment")
      end

      it "still renders the file input so the user can re-choose" do
        expect(html).to have_field("profile[avatar]", type: :file, visible: :all)
      end

      it "leaves no half-persisted blob behind" do
        html

        expect(profile.attachment_changes["avatar"].blob).not_to be_persisted
      end

      # ActiveStorage's log subscriber only reports successful service calls
      # (it ignores the exception payload), so once the field swallows the
      # error, this warning is the only record that a user's file was dropped.
      it "logs the dropped upload" do
        allow(Rails.logger).to receive(:warn)

        html

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
        Capybara.string(builder.govuk_attachment_field(:gallery).to_s)
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

  describe "#govuk_attachment_field (gallery / multiple)" do
    subject(:html) { govuk_attachment_field(:gallery) }

    context "with no attachments" do
      let(:profile) { Profile.new }

      it "renders no attachment figures" do
        expect(html).to have_no_css("figure.govuk-attachment")
      end

      it "infers multiple from the has_many_attached reflection" do
        expect(html).to have_css("input[type=file][multiple]", visible: :all)
      end

      it "renders a multiple file input when multiple is passed explicitly" do
        html = govuk_attachment_field(:gallery, multiple: true)

        expect(html).to have_css("input[type=file][multiple]", visible: :all)
      end

      it "renders without multiple file input when multiple is passed explicitly" do
        html = govuk_attachment_field(:gallery, multiple: false)

        expect(html).to have_css("input[type=file]:not([multiple])", visible: :all)
      end
    end

    context "with several attached images" do
      before do
        %w[first.png second.png].each do |filename|
          profile.gallery.attach(
            io:           File.open(file_fixture("avatar.png")),
            filename:,
            content_type: "image/png",
          )
        end
      end

      it "renders one figure per attached file, in attachment order" do
        expect(html.all("figure.govuk-attachment .filename").map(&:text)).to eq(%w[first.png second.png])
      end

      it "round-trips each attachment via its own array-named select" do
        profile.gallery.blobs.each do |blob|
          expect(html).to have_css(
            "select[name='profile[gallery][]'] option[selected][value='#{blob.signed_id}']",
            text:    blob.filename.to_s,
            visible: :all,
          )
        end
      end

      it "offers a remove option naming each file" do
        %w[first.png second.png].each do |filename|
          expect(html).to have_css(
            "figure.govuk-attachment select option[value='']",
            text:    "Remove #{filename}",
            visible: :all,
          )
        end
      end

      it "gives each select a unique per-blob id" do
        ids = html.all("figure.govuk-attachment select", visible: :all).map { |select| select["id"] }

        expect(ids).to eq(profile.gallery.blobs.map { |blob| builder.field_id(:gallery, :attachment, blob.id, :input) })
      end

      it "renders the blank keeper first, before the other input(s)" do
        types = html.all("[name='profile[gallery][]']", visible: :all).map do |node|
          "#{node.tag_name}[type=#{node['type']}]"
        end

        expect(types).to eq(%w[input[type=hidden] select[type=] select[type=] input[type=file]])
      end
    end
  end

  # cv (optional has_one, PDF) renders the same markup as avatar (required
  # has_one, image) — PDFs are representable wherever a previewer (poppler)
  # is available, so even the preview appears; these examples pin only the
  # attribute's own scalar round-trip.
  describe "#govuk_attachment_field (cv / single / optional)" do
    subject(:html) { govuk_attachment_field(:cv) }

    context "with an attached file" do
      before do
        profile.cv.attach(
          io:           File.open(file_fixture("cv.pdf")),
          filename:     "cv.pdf",
          content_type: "application/pdf",
        )
      end

      let(:blob) { profile.cv.blob }

      it "renders one figure with caption, and actions, in order" do
        expect(html).to have_css("figure.govuk-attachment > figcaption + div.actions", count: 1, visible: :all)
      end

      it "selects the current file, labelled with its filename" do
        expect(html).to have_css(
          "figure.govuk-attachment select option[selected][value='#{blob.signed_id}']",
          text:    "cv.pdf",
          visible: :all,
        )
      end

      it "names the select for scalar assignment" do
        select = html.find("figure.govuk-attachment select", visible: :all)

        expect(select["name"]).to eq("profile[cv]")
      end
    end
  end
end
