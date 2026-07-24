# frozen_string_literal: true

require "rails_helper"

# A JS-injected figure and a server-rendered figure for the same file should
# be interchangeable: styling, the round-trip param shape, and re-enhancement
# after a morph all assume one figure shape. This spec captures both from the
# same live page — the server figure rendered for the persisted attachment,
# and the client figure created by choosing the same fixture file — and
# compares canonical forms.
#
# Canonicalisation (spec/support/canonical_markup.rb) makes the comparison
# target structure, not incidentals — id wiring rather than id values, and
# tokenised signed ids and URLs, since the two figures hold different blobs
# by construction. On top of that, the upload lifecycle is scrubbed: only a
# figure that lived through an upload carries data-state and status text, by
# design.
RSpec.describe "Attachment markup parity" do
  include AttachmentFieldHelpers
  include CanonicalMarkup

  let(:profile) { create(:profile) }

  it "renders the same figure for an upload as the server renders for its attachment" do
    visit edit_profile_path(profile)

    server_figure = avatar_field.find("figure.govuk-attachment").evaluate_script("this.outerHTML")

    choose_avatar_file("avatar.png")

    client_figure = avatar_field
                      .find("figure.govuk-attachment[data-state=upload-successful]", wait: 10)
                      .evaluate_script("this.outerHTML")

    expect(canonical_figure(client_figure)).to eq(canonical_figure(server_figure))
  end

  def canonical_figure(html)
    canonical_markup(scrub_upload_state(Nokogiri::HTML5.fragment(html).at_css("figure")))
  end

  private

  # Only a figure that lived through an upload carries lifecycle state:
  # server figures render with no data-state and an empty status span.
  # Remove a line here to surface that difference in the diff instead.
  def scrub_upload_state(figure)
    figure.remove_attribute("data-state")
    figure.at_css("figcaption .status")&.content = ""
    figure
  end
end
