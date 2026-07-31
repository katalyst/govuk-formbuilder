# frozen_string_literal: true

require "rails_helper"

# Previews are contained, never cropped or squashed: the preview box is square
# so figures line up down a list, and the image inside keeps its own aspect,
# letterboxed by CSS. Client-inserted previews carry the image's natural
# dimensions (a data URL of the chosen file), so they are the strict case —
# the server variant arrives pre-fitted.
RSpec.describe "Attachment preview framing", :aggregate_failures do
  include AttachmentFieldHelpers
  include DirectUploadHelpers

  let(:profile) { create(:profile) }

  before { disable_direct_uploads }

  # banner.png is 3:1.
  it "shows a non-square preview whole, undistorted" do
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
    expect(framing["fit"]).to eq("contain")
  end
end
