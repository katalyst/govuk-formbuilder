# frozen_string_literal: true

require "rails_helper"

# Dropping files onto the attachment field, ported from govuk-frontend's
# FileUpload with one intended difference: the drop target is the whole
# wrapper, figures included, not just the button (upstream's button is its
# whole zone; ours shares the wrapper with figures). A valid drag shows the
# dragging state and is announced, and a drop fills the input exactly as
# choosing files does. Drops are simulated with a synthetic DragEvent
# carrying a DataTransfer, which exercises the real controller in the
# browser (OS-level drag can't be driven from Capybara).
RSpec.describe "Dropping files onto an attachment field", :aggregate_failures do
  include AttachmentFieldHelpers
  include DirectUploadHelpers

  let(:profile) { create(:profile) }

  it "uploads a dropped file like a chosen one" do
    visit edit_profile_path(profile)

    drop_files("profile[gallery][]", "avatar.png")

    expect(gallery_field).to have_css("figure.govuk-attachment[data-state=upload-successful]", wait: 10)
    expect(gallery_field).to have_css("figure.govuk-attachment .filename", text: "avatar.png")
  end

  context "without a direct-upload endpoint" do
    before { disable_direct_uploads }

    it "previews a dropped file" do
      visit edit_profile_path(profile)

      drop_files("profile[gallery][]", "avatar.png")

      expect(gallery_field).to have_css("figure.govuk-attachment .filename", text: "avatar.png")
    end

    it "accepts several files dropped on a multiple field" do
      visit edit_profile_path(profile)

      drop_files("profile[gallery][]", "avatar.png", "cv.pdf")

      expect(gallery_field).to have_css("figure.govuk-attachment", count: 2)
    end

    it "rejects a multi-file drop on a single-file field" do
      visit edit_profile_path(profile)

      # cv: single-file and optional, so the field is verifiably empty after
      # the rejected drop (avatar always carries its persisted figure).
      drop_files("profile[cv]", "avatar.png", "cv.pdf")

      expect(cv_field).to have_no_css("figure.govuk-attachment")
    end

    it "accepts a drop on a figure, away from the button" do
      visit edit_profile_path(profile)

      # avatar always carries its persisted figure, making the non-button
      # surface of the drop zone real.
      drop_files("profile[avatar]", "dropped.png", target: "figure.govuk-attachment")

      expect(avatar_field).to have_css("figure.govuk-attachment .filename", text: "dropped.png")
    end

    it "ignores a drop on a disabled field" do
      visit edit_profile_path(profile)

      page.execute_script("document.querySelector(`input[type=file][name='profile[cv]']`).disabled = true")
      drop_files("profile[cv]", "dropped.png")

      expect(cv_field).to have_no_css("figure.govuk-attachment")
    end
  end

  it "shows the dragging state and announces entering and leaving the drop zone" do
    visit edit_profile_path(profile)

    dispatch_drag("dragenter", gallery_drop_target)

    expect(gallery_field).to have_css(".govuk-file-upload-button--dragging")
    expect(announcements_region(gallery_field)).to have_text("Entered drop zone")

    # A dragenter on an element outside the zone means the drag has left it.
    dispatch_drag("dragenter", "body")

    expect(gallery_field).to have_no_css(".govuk-file-upload-button--dragging")
    expect(announcements_region(gallery_field)).to have_text("Left drop zone")
  end

  def gallery_drop_target
    ".govuk-file-upload-wrapper:has(input[name='profile[gallery][]']) .govuk-file-upload-button"
  end

  # Dispatch a synthetic drop of `filenames` onto the field's wrapper — or
  # onto `target`, a selector within it. The File contents are stub bytes —
  # enough for a preview and a direct upload.
  def drop_files(input_name, *filenames, target: nil)
    page.execute_script(<<~JS, input_name, filenames, target)
      const [name, names, target] = arguments;
      const wrapper = document
        .querySelector(`input[type=file][name="${name}"]`)
        .closest(".govuk-file-upload-wrapper");
      const element = target ? wrapper.querySelector(target) : wrapper;
      const data = new DataTransfer();
      names.forEach((n) => data.items.add(new File(["stub"], n, { type: "image/png" })));
      element.dispatchEvent(
        new DragEvent("drop", { dataTransfer: data, bubbles: true, cancelable: true }),
      );
    JS
  end

  # Dispatch a synthetic drag event (carrying one dragged file) on the element
  # matching `selector`.
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
