# frozen_string_literal: true

require "rails_helper"

# Server-rendered markup for govuk_document_field backed by Profile's
# has_one_attached :cv: one figure per attached blob (caption,
# keep/remove select) and a direct-upload-ready file input.
# Pending examples pin agreed behaviour that is not implemented yet.
RSpec.describe "govuk_document_field" do
  subject(:html) { Capybara.string(builder.govuk_document_field(:cv).to_s) }

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
      expect(html).to have_css("input[type=file][accept*='application/pdf']", visible: :all)
    end

    # Exclusivity invariant: initAll enhances data-module="govuk-file-upload"
    # with govuk-frontend's own FileUpload, so an attachment field emitting it
    # would have two implementations fighting over one input.
    it "never emits govuk-frontend's file-upload data-module" do
      expect(html).to have_no_css("[data-module='govuk-file-upload']", visible: :all)
    end
  end

  context "with an attached file" do
    let(:object) do
      create(:profile).tap do |profile|
        profile.cv.attach(
          io:           File.open(file_fixture("cv.pdf")),
          filename:     "cv.pdf",
          content_type: "application/pdf",
        )
      end
    end

    let(:blob) { object.cv.blob }

    it "renders one figure with caption, and actions, in order" do
      expect(html).to have_css("figure.govuk-attachment > figcaption + div.actions", count: 1, visible: :all)
    end

    it "groups the select and remove button in the actions container" do
      expect(html).to have_css("figure.govuk-attachment .actions > select + button", visible: :all)
    end

    it "captions the figure with the filename" do
      expect(html).to have_css("figure.govuk-attachment figcaption .filename", text: "cv.pdf")
    end

    it "captions the figure with the human file size" do
      expect(html).to have_css("figure.govuk-attachment figcaption .size", text: /\A[\d.]+ (Bytes|KB|MB)\z/)
    end

    it "selects the current file, labelled with its filename" do
      expect(html).to have_css(
        "figure.govuk-attachment select option[selected][value='#{blob.signed_id}']",
        text:    "cv.pdf",
        visible: :all,
      )
    end

    it "offers a remove option with a blank value naming the file" do
      expect(html).to have_css(
        "figure.govuk-attachment select option[value='']",
        text:    "Remove cv.pdf",
        visible: :all,
      )
    end

    it "names the select for scalar assignment" do
      select = html.find("figure.govuk-attachment select", visible: :all)

      expect(select["name"]).to eq("profile[cv]")
    end

    it "gives the select a unique per-blob id" do
      select = html.find("figure.govuk-attachment select", visible: :all)

      expect(select["id"]).to eq(builder.field_id(:cv, :attachment, blob.id, :input))
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

      expect(button["aria-label"]).to eq("Remove cv.pdf")
    end

    it "stops the remove button from submitting the form" do
      button = html.find("figure.govuk-attachment .actions button")

      expect(button["type"]).to eq("button")
    end

    it "labels the figure with its caption" do
      figure = html.find("figure.govuk-attachment")

      expect(figure["aria-labelledby"]).to eq(builder.field_id(:cv, :attachment, blob.id, :caption))
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

      expect([select["aria-label"], *referenced, *label_texts].compact.join(" ")).to include("cv.pdf")
    end
  end

  describe "#direct_upload_url" do
    let(:object) { Profile.new }

    it "adds data-direct-upload-url by default" do
      input = html.find("input[type=file]", visible: :all)

      expect(input["data-direct-upload-url"]).to eq(helper.rails_direct_uploads_url)
    end

    it "respects direct_upload: false" do
      html = Capybara.string(builder.govuk_document_field(:cv, direct_upload: false).to_s)

      expect(html).to have_css("input[type=file]:not([data-direct-upload-url])", visible: :all)
    end

    context "with an attached file and direct_upload: false" do
      let(:object) do
        create(:profile).tap do |profile|
          profile.cv.attach(
            io:           File.open(file_fixture("cv.pdf")),
            filename:     "cv.pdf",
            content_type: "application/pdf",
          )
        end
      end

      # The keep/remove select round-trip works without direct upload; opting
      # out of async upload must not degrade the attachment markup.
      it "still renders the attachment figure" do
        html = Capybara.string(builder.govuk_document_field(:cv, direct_upload: false).to_s)

        expect(html).to have_css("figure.govuk-attachment > figcaption + div.actions", visible: :all)
      end
    end

    it "uses direct_upload_url when provided" do
      html  = Capybara.string(builder.govuk_document_field(:cv, direct_upload_url: "/override").to_s)
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
