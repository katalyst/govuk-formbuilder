# frozen_string_literal: true

require "rails_helper"

# The builder's text options render as data-i18n.* attributes on the
# wrapper, and the enhancement reads its strings from them, falling back to
# its bundled defaults when they are absent. Driven through a test-support
# example (examples/attachment/i18n) whose options are all sentinel values,
# so a passing assertion cannot have been met by the English defaults.
#
# Locale (the closest `lang` attribute) feeds plural-form selection, but the
# builder only renders one/other forms — every count resolves to one of them
# in any locale, so locale handling has no observable surface to pin here.
RSpec.describe "Attachment field i18n", :aggregate_failures do
  include AttachmentFieldHelpers
  include DirectUploadHelpers

  let(:page_path) { example_path("attachment", "i18n") }

  it "builds the upload button from the configured strings" do
    visit page_path

    field = attachment_field("profile[gallery][]")

    expect(field).to have_css(".govuk-file-upload-button__pseudo-button", text: "XX pick files XX", wait: 5)
    expect(field).to have_css(".govuk-file-upload-button__instruction", text: "XX or drop XX")
    expect(field).to have_css(".govuk-file-upload-button__status", text: "XX empty XX")
  end

  it "counts a single chosen file with the one form" do
    visit page_path

    choose_gallery_files("avatar.png")

    expect(status_region(attachment_field("profile[gallery][]"))).to have_text("XX one file: 1 XX")
  end

  it "counts several chosen files with the other form" do
    visit page_path

    choose_gallery_files("avatar.png", "cv.pdf")

    expect(status_region(attachment_field("profile[gallery][]"))).to have_text("XX many files: 2 XX")
  end

  it "reports upload success with the configured string" do
    visit page_path

    choose_gallery_files("avatar.png")

    figure = attachment_field("profile[gallery][]")
               .find("figure.govuk-attachment[data-state=upload-successful]", wait: 10)

    expect(figure).to have_css("figcaption .status", text: "XX stored XX")
  end

  it "reports upload failure and offers retry with the configured strings" do
    break_direct_uploads
    visit page_path

    choose_gallery_files("avatar.png")

    figure = attachment_field("profile[gallery][]")
               .find("figure.govuk-attachment[data-state=upload-failed]", wait: 10)

    expect(figure).to have_css("figcaption .status", text: "XX broken XX")
    expect(figure).to have_css(
      "button[type=button][aria-label='XX retry XX avatar.png']",
      text: "XX retry XX",
    )
  end

  it "builds the figure's remove control from the configured strings" do
    visit page_path

    choose_gallery_files("avatar.png")

    figure = attachment_field("profile[gallery][]").find("figure.govuk-attachment", wait: 10)

    expect(figure).to have_css("button[aria-label='XX bin avatar.png XX']", text: "XX x XX")
    expect(figure).to have_css("select option[value='']", text: "XX bin avatar.png XX", visible: :all)
  end

  it "announces a removal with the configured string, naming the file" do
    visit page_path

    choose_gallery_files("avatar.png")

    field = attachment_field("profile[gallery][]")
    field.find("figure.govuk-attachment[data-state=upload-successful]", wait: 10)

    field.find("button[aria-label='XX bin avatar.png XX']").click

    expect(announcements_region(field)).to have_text("XX avatar.png gone XX")
  end

  it "announces the drop zone with the configured strings" do
    visit page_path

    field = attachment_field("profile[gallery][]")
    field.find(".govuk-file-upload-button", wait: 5)

    dispatch_drag("dragenter", drop_target)

    expect(announcements_region(field)).to have_text("XX over zone XX")

    # A dragenter outside the zone means the drag has left it.
    dispatch_drag("dragenter", "body")

    expect(announcements_region(field)).to have_text("XX out of zone XX")
  end

  def drop_target
    ".govuk-file-upload-wrapper:has(input[name='profile[gallery][]']) .govuk-file-upload-button"
  end

  def choose_gallery_files(*fixtures)
    paths = fixtures.map { |fixture| file_fixture(fixture).to_s }

    within(attachment_field("profile[gallery][]")) do
      attach_file("profile[gallery][]", paths, make_visible: true)
    end
  end

  # Dispatch a synthetic drag event (carrying one dragged file) on the
  # element matching `selector`.
  def dispatch_drag(type, selector)
    page.execute_script(<<~JS, type, selector)
      const [type, selector] = arguments;
      const data = new DataTransfer();
      data.items.add(new File(["stub"], "dragged.png", { type: "image/png" }));
      document.querySelector(selector).dispatchEvent(
        new DragEvent(type, { dataTransfer: data, bubbles: true, cancelable: true }),
      );
    JS
  end
end
