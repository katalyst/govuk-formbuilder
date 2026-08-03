# frozen_string_literal: true

require "rails_helper"

# The preview box is square so figures line up down a list, and the image
# fills it (`object-fit: cover`): centre-cropped, never squashed.
# Client-inserted previews carry the image's natural dimensions (a data URL
# of the chosen file), so they are the strict case — the server variant
# arrives pre-cropped square (`resize_to_fill`).
RSpec.describe "Attachment preview framing", :aggregate_failures do
  include AttachmentFieldHelpers
  include DirectUploadHelpers

  let(:profile) { create(:profile) }

  before { disable_direct_uploads }

  # banner.png is 3:1.
  it "fills the square preview box from a non-square image, undistorted" do
    visit edit_profile_path(profile)

    choose_gallery_file("banner.png")

    framing = gallery_field
                .find("figure.govuk-attachment img.preview")
                .evaluate_async_script(<<~JS)
                  const done = arguments[arguments.length - 1];
                  const measure = () => done({
                    box: this.clientWidth / this.clientHeight,
                    natural: this.naturalWidth / this.naturalHeight,
                    fit: getComputedStyle(this).objectFit,
                  });
                  this.complete && this.naturalWidth
                    ? measure()
                    : this.addEventListener("load", measure, { once: true });
                JS

    expect(framing["box"]).to be_within(0.01).of(1)
    expect(framing["natural"]).to be_within(0.01).of(3)
    expect(framing["fit"]).to eq("cover")
  end

  # Only image/* files can render as an img source. A non-image figure
  # carries no preview img at all — the same shape the server renders for
  # a non-representable blob.
  it "renders a non-image figure without a preview img" do
    visit edit_profile_path(profile)

    choose_cv_file("cv.pdf")

    expect(cv_field).to have_css("figure.govuk-attachment", count: 1)
    expect(cv_field).to have_no_css("figure.govuk-attachment img")
  end
end
