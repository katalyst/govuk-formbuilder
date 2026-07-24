# frozen_string_literal: true

require "rails_helper"

RSpec.describe GOVUKDesignSystemFormBuilder::FormBuilder do
  let(:builder) { described_class.new(:profile, profile, helper, {}) }
  let(:profile) { create(:profile) }

  def govuk_document_field(...)
    Capybara.string(builder.govuk_document_field(...).to_s)
  end

  describe "#govuk_document_field" do
    subject(:html) { govuk_document_field(:cv) }

    let(:blob) { profile.cv.blob }

    context "with no attachment" do
      let(:profile) { Profile.new }

      it "renders no attachment figures" do
        expect(html).to have_no_css("figure.govuk-attachment")
      end

      it "renders a single file input inside the wrapper" do
        expect(html).to have_css(".govuk-file-upload-wrapper input[type=file]", count: 1, visible: :all)
      end

      it "applies the document mime types to the input's accept attribute" do
        expect(html).to have_css("input[type=file][accept*='application/pdf']", visible: :all)
      end
    end

    # govuk_document_field delegates to govuk_attachment_field;
    # the label, caption, hint and form_group configuration must reach it rather
    # than being dropped on the way through.
    context "with configuration options" do
      it "renders the hint" do
        html = govuk_document_field(:cv, hint: { text: "Max 5MB" })

        expect(html).to have_css(".govuk-hint", text: "Max 5MB")
      end

      it "describes the input by the hint" do
        html    = govuk_document_field(:cv, hint: { text: "Max 5MB" })
        hint_id = html.find(".govuk-hint", visible: :all)[:id]

        expect(html.find("input[type=file]", visible: :all)["aria-describedby"]).to eq(hint_id)
      end

      it "renders the supplied label text" do
        html = govuk_document_field(:cv, label: { text: "Your CV" })

        expect(html).to have_css("label", text: "Your CV")
      end

      it "renders the supplied caption" do
        html = govuk_document_field(:cv, caption: { text: "Step 1" })

        expect(html).to have_css(".govuk-caption-m", text: "Step 1")
      end

      it "applies form_group options" do
        html = govuk_document_field(:cv, form_group: { class: "extra-group" })

        expect(html).to have_css(".govuk-form-group.extra-group")
      end
    end

    context "with an attached file" do
      before do
        profile.cv.attach(
          io:           File.open(file_fixture("cv.pdf")),
          filename:     "cv.pdf",
          content_type: "application/pdf",
        )
      end

      it "renders one figure with caption, and actions, in order" do
        expect(html).to have_css("figure.govuk-attachment > figcaption + div.actions", count: 1, visible: :all)
      end
    end

    context "with an image attachment" do
      before do
        profile.cv.attach(
          io:           File.open(file_fixture("avatar.png")),
          filename:     "avatar.png",
          content_type: "image/png",
        )
      end

      it "renders the figure with preview, caption, and actions adjacent" do
        expect(html).to have_css("figure.govuk-attachment > img + figcaption + div.actions", visible: :all)
      end
    end
  end
end
