# frozen_string_literal: true

require "rails_helper"

# Server-rendered markup for govuk_image_field backed by Profile's
# has_one_attached :avatar: one figure per attached blob (preview image,
# caption, keep/remove select) and a direct-upload-ready file input.
# Pending examples pin agreed behaviour that is not implemented yet.
RSpec.describe "govuk_image_field" do
  subject(:html) { Capybara.string(builder.govuk_image_field(:avatar).to_s) }

  let(:builder) { GOVUKDesignSystemFormBuilder::FormBuilder.new(:profile, object, helper, {}) }

  context "with no attachment" do
    let(:object) { Profile.new }

    it "renders no attachment figures" do
      expect(html).to have_no_css("figure.govuk-attachment")
    end

    it "renders a single file input inside the wrapper" do
      expect(html).to have_css(".govuk-file-upload-wrapper input[type=file]", count: 1, visible: :all)
    end

    it "does not mark the file input as multiple" do
      expect(html).to have_no_css("input[type=file][multiple]", visible: :all)
    end

    it "applies the image mime types to the input's accept attribute" do
      expect(html).to have_css("input[type=file][accept*='image/png']", visible: :all)
    end

    # Exclusivity invariant: initAll enhances data-module="govuk-file-upload"
    # with govuk-frontend's own FileUpload, so an attachment field emitting it
    # would have two implementations fighting over one input.
    it "never emits govuk-frontend's file-upload data-module" do
      expect(html).to have_no_css("[data-module='govuk-file-upload']", visible: :all)
    end
  end

  # govuk_image_field / govuk_document_field delegate to govuk_attachment_field;
  # the label, caption, hint and form_group configuration must reach it rather
  # than being dropped on the way through.
  context "with configuration options" do
    let(:object) { Profile.new }

    it "renders the hint" do
      html = Capybara.string(builder.govuk_image_field(:avatar, hint: { text: "Max 5MB" }).to_s)

      expect(html).to have_css(".govuk-hint", text: "Max 5MB")
    end

    it "describes the input by the hint" do
      html    = Capybara.string(builder.govuk_image_field(:avatar, hint: { text: "Max 5MB" }).to_s)
      hint_id = html.find(".govuk-hint", visible: :all)[:id]

      expect(html.find("input[type=file]", visible: :all)["aria-describedby"]).to eq(hint_id)
    end

    it "renders the supplied label text" do
      html = Capybara.string(builder.govuk_image_field(:avatar, label: { text: "Your photo" }).to_s)

      expect(html).to have_css("label", text: "Your photo")
    end

    it "renders the supplied caption" do
      html = Capybara.string(builder.govuk_image_field(:avatar, caption: { text: "Step 1" }).to_s)

      expect(html).to have_css(".govuk-caption-m", text: "Step 1")
    end

    it "applies form_group options" do
      html = Capybara.string(builder.govuk_image_field(:avatar, form_group: { class: "extra-group" }).to_s)

      expect(html).to have_css(".govuk-form-group.extra-group")
    end
  end

  context "with an attached image" do
    let(:object) { create(:profile) }
    let(:blob) { object.avatar.blob }

    it "renders one figure with preview, caption, and actions, in order" do
      expect(html).to have_css("figure.govuk-attachment > img + figcaption + div.actions", count: 1, visible: :all)
    end

    it "groups the select and remove button in the actions container" do
      expect(html).to have_css("figure.govuk-attachment .actions > select + button", visible: :all)
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

  context "with a non-image attachment" do
    let(:object) do
      create(:profile).tap do |profile|
        profile.avatar.attach(
          io:           StringIO.new("not an image"),
          filename:     "notes.txt",
          content_type: "text/plain",
        )
      end
    end

    it "renders the figure with caption and actions adjacent" do
      expect(html).to have_css("figure.govuk-attachment > figcaption + div.actions", visible: :all)
    end

    it "omits the preview image" do
      expect(html).to have_no_css("figure.govuk-attachment img")
    end
  end

  describe "#direct_upload_url" do
    let(:object) { Profile.new }

    it "adds data-direct-upload-url by default" do
      input = html.find("input[type=file]", visible: :all)

      expect(input["data-direct-upload-url"]).to eq(helper.rails_direct_uploads_url)
    end

    it "respects direct_upload: false" do
      html = Capybara.string(builder.govuk_image_field(:avatar, direct_upload: false).to_s)

      expect(html).to have_css("input[type=file]:not([data-direct-upload-url])", visible: :all)
    end

    context "with an attached image and direct_upload: false" do
      let(:object) do
        create(:profile).tap do |profile|
          profile.avatar.attach(
            io:           File.open(file_fixture("avatar.png")),
            filename:     "avatar.png",
            content_type: "image/png",
          )
        end
      end

      # The keep/remove select round-trip works without direct upload; opting
      # out of async upload must not degrade the attachment markup.
      it "still renders the attachment figure" do
        html = Capybara.string(builder.govuk_image_field(:avatar, direct_upload: false).to_s)

        expect(html).to have_css("figure.govuk-attachment > img + figcaption + div.actions", visible: :all)
      end
    end

    it "uses direct_upload_url when provided" do
      html  = Capybara.string(builder.govuk_image_field(:avatar, direct_upload_url: "/override").to_s)
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
end
