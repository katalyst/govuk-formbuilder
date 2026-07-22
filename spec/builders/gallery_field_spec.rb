# frozen_string_literal: true

require "rails_helper"

# The multiple-file counterpart to image_field_spec.rb, backed by Profile's
# has_many_attached :gallery. Covers the array-name and per-blob aspects of
# the figure/select markup: each blob round-trips through its own select.
# Pending examples pin agreed behaviour that is not implemented yet.
RSpec.describe "govuk_image_field (gallery / multiple)" do
  subject(:html) { Capybara.string(builder.govuk_image_field(:gallery, multiple: true).to_s) }

  let(:builder) { GOVUKDesignSystemFormBuilder::FormBuilder.new(:profile, object, helper, {}) }

  context "with no attachments" do
    let(:object) { Profile.new }

    it "renders no attachment figures" do
      expect(html).to have_no_css("figure.govuk-attachment")
    end

    it "renders a multiple file input when multiple is passed explicitly" do
      expect(html).to have_css("input[type=file][multiple]", visible: :all)
    end

    it "infers multiple from the has_many_attached reflection" do
      unhinted = Capybara.string(builder.govuk_image_field(:gallery).to_s)

      expect(unhinted).to have_css("input[type=file][multiple]", visible: :all)
    end
  end

  context "with several attached images" do
    let(:object) do
      create(:profile).tap do |profile|
        %w[first.png second.png].each do |filename|
          profile.gallery.attach(
            io:           File.open(file_fixture("avatar.png")),
            filename:,
            content_type: "image/png",
          )
        end
      end
    end

    it "renders one figure per attached file, in attachment order" do
      expect(html.all("figure.govuk-attachment .filename").map(&:text)).to eq(%w[first.png second.png])
    end

    it "round-trips each attachment via its own array-named select" do
      object.gallery.blobs.each do |blob|
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

      expect(ids).to eq(object.gallery.blobs.map { |blob| builder.field_id(:gallery, :attachment, blob.id, :input) })
    end
  end
end
