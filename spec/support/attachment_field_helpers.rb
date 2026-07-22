# frozen_string_literal: true

# Finders and interactions for the profile form's attachment fields, shared
# by the system specs in spec/system/attachment/.
module AttachmentFieldHelpers
  # The enhanced field (drop zone) wrapping the file input with this name.
  def attachment_field(name)
    find("[data-controller='govuk-file-upload']:has(input[type=file][name='#{name}'])")
  end

  def gallery_field
    attachment_field("profile[gallery][]")
  end

  def avatar_field
    attachment_field("profile[avatar]")
  end

  # The document (non-image) counterpart: cv is optional where avatar is
  # required, and its figures render without a preview image.
  def cv_field
    attachment_field("profile[cv]")
  end

  # The upload button's status span is the field's polite live region: it
  # carries the field's state — the file count.
  def status_region(field)
    field.find("button [aria-live]")
  end

  # The field's assertive live region: it carries event announcements (drag
  # enter/leave, removals). Visually hidden, so found with visible: :all.
  def announcements_region(field)
    field.find(".govuk-file-upload-announcements", visible: :all)
  end

  # The file input is hidden once JavaScript enhances the field; Capybara
  # needs it visible to attach a fixture through it.
  def choose_file(name, fixture)
    within(attachment_field(name)) do
      attach_file(name, file_fixture(fixture).to_s, make_visible: true)
    end
  end

  def choose_gallery_file(fixture)
    choose_file("profile[gallery][]", fixture)
  end

  def choose_avatar_file(fixture)
    choose_file("profile[avatar]", fixture)
  end

  def choose_cv_file(fixture)
    choose_file("profile[cv]", fixture)
  end
end
