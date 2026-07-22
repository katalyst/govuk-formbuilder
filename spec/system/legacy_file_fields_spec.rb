# frozen_string_literal: true

require "rails_helper"

# Exercises the Stimulus controllers that back govuk_image_field and
# govuk_document_field (app/javascript/katalyst/govuk/controllers/*). These
# enhance a plain file input with a live preview, a "remove" button and
# drag-and-drop, none of which can be observed without a real browser.
RSpec.describe "Legacy file fields javascript" do
  delegate :config, to: :GOVUKDesignSystemFormBuilder

  around do |example|
    config.use_legacy_file_fields = true
    example.run
  ensure
    config.use_legacy_file_fields = false
  end

  describe "image field" do
    it "previews the chosen image and can remove it", :aggregate_failures do
      visit new_profile_path

      within(avatar_field) do
        # No file chosen yet, so the preview is hidden.
        expect(page).to have_css("[data-govuk-image-field-target=preview]", visible: :hidden)

        attach_file("profile[avatar]", file_fixture("avatar.png").to_s)

        # onUpload reveals the preview and showPreview loads the file into the
        # <img> as a data URL via FileReader.
        expect(page).to have_css("[data-govuk-image-field-target=preview]", visible: :visible, wait: 5)
        expect(find("img.image-thumbnail")["src"]).to start_with("data:image/png")

        # setDestroy hides the preview again and clears the file input.
        click_button(class: "file-destroy")

        expect(page).to have_css("[data-govuk-image-field-target=preview]", visible: :hidden)
        expect(find("input[name='profile[avatar]']", visible: :all).value).to eq("")
      end
    end
  end

  describe "document field" do
    it "previews the chosen filename and can remove it", :aggregate_failures do
      visit new_profile_path

      within(".govuk-document-field") do
        expect(page).to have_css("[data-govuk-document-field-target=preview]", visible: :hidden)

        attach_file("profile[cv]", file_fixture("cv.pdf").to_s)

        # showPreview writes the chosen file's name into the preview paragraph.
        expect(page).to have_css("[data-govuk-document-field-target=preview]", visible: :visible, wait: 5)
        expect(page).to have_css("p.preview-filename", text: "cv.pdf")

        click_button(class: "file-destroy")

        expect(page).to have_css("[data-govuk-document-field-target=preview]", visible: :hidden)
        expect(find("input[name='profile[cv]']", visible: :all).value).to eq("")
      end
    end
  end

  describe "drag-and-drop affordance" do
    # The controller toggles a `droppable` class while a file is dragged over
    # the field, using a counter so nested dragenter/dragleave pairs balance out.
    it "highlights the field on dragenter and clears it on dragleave", :aggregate_failures do
      visit new_profile_path

      field = avatar_field

      expect(field[:class]).not_to include("droppable")

      dispatch_drag_event(field, "dragenter")
      expect(field[:class]).to include("droppable")

      dispatch_drag_event(field, "dragleave")
      expect(field[:class]).not_to include("droppable")
    end
  end

  # The form renders two image fields (avatar and gallery); scope to avatar's.
  def avatar_field
    find(".govuk-image-field:has(input[name='profile[avatar]'])")
  end

  # Dispatches a DragEvent carrying an (empty) DataTransfer onto the element, so
  # the controller's dragenter/dragleave handlers run exactly as they would for
  # a real drag interaction. Cuprite has no native drag-with-files API.
  def dispatch_drag_event(node, type)
    node.execute_script(<<~JS, type)
      const type = arguments[0];
      const event = new DragEvent(type, { bubbles: true, cancelable: true });
      this.dispatchEvent(event);
    JS
  end
end
