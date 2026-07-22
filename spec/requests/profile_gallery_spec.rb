# frozen_string_literal: true

require "rails_helper"

# Exercises updating Profile#gallery (has_many_attached) through the controller.
#
# The gallery field round-trips as an array of `profile[gallery][]` values that
# mirrors the rendered form: a leading blank entry, then one hidden input per
# retained file carrying that blob's signed id, then the type=file input (empty
# in these specs — new files arrive as signed ids from the async direct upload).
#
# Because has_many_attached replaces the whole collection on assignment, the set
# submitted IS the resulting set:
#   * the blank keeps the param present so an otherwise-empty array still clears
#   * a signed id that's present is retained; one that's dropped is removed
#   * a brand-new signed id is added
RSpec.describe "Updating a profile's gallery" do
  let(:profile) { Profile.create!(name: "Ada Lovelace", email: "ada@example.com") }

  # Mirrors the submitted field order: blank first, then a signed id per file.
  def gallery_params(*signed_ids)
    { profile: { gallery: ["", *signed_ids] } }
  end

  # A blob that exists but isn't attached to the profile yet — stands in for a
  # file the browser has already direct-uploaded and injected as a hidden input.
  def uploaded_blob(filename)
    ActiveStorage::Blob.create_and_upload!(
      io:           File.open(file_fixture("avatar.png")),
      filename:,
      content_type: "image/png",
    )
  end

  # Attaches a file directly, as though it were saved on a previous request.
  def attach_existing(filename)
    profile.gallery.attach(io: File.open(file_fixture("avatar.png")), filename:, content_type: "image/png")
    profile.gallery.blobs.find { |blob| blob.filename.to_s == filename }
  end

  describe "adding a single file (none => 1)" do
    let(:blob) { uploaded_blob("added.png") }

    it "attaches the newly uploaded blob" do
      patch profile_path(profile), params: gallery_params(blob.signed_id)

      expect(profile.reload.gallery.blobs).to contain_exactly(blob)
    end

    it "redirects back to the profile" do
      patch profile_path(profile), params: gallery_params(blob.signed_id)

      expect(response).to have_http_status(:see_other)
    end
  end

  describe "removing the only file (1 => none)" do
    it "detaches it when just the blank entry is submitted" do
      attach_existing("existing.png")

      expect do
        patch profile_path(profile), params: gallery_params
      end.to change { profile.reload.gallery.count }.from(1).to(0)
    end
  end

  describe "adding one and removing another (1 => 1)" do
    it "replaces the old blob with the new one" do
      attach_existing("existing.png")
      new_blob = uploaded_blob("added.png")

      # The existing signed id is omitted (removed) and the new one submitted.
      # contain_exactly is exhaustive: the new blob is the whole gallery.
      patch profile_path(profile), params: gallery_params(new_blob.signed_id)

      expect(profile.reload.gallery.blobs).to contain_exactly(new_blob)
    end
  end

  describe "submitting an unchanged gallery (1 => 1)" do
    it "keeps the same blob attached" do
      existing = attach_existing("existing.png")

      patch profile_path(profile), params: gallery_params(existing.signed_id)

      expect(profile.reload.gallery.blobs).to contain_exactly(existing)
    end
  end

  # Without JS there's no async direct upload, so files arrive as real multipart
  # uploads through the type=file input, appended after the blank entry (and any
  # retained signed ids) in the same profile[gallery][] array.
  describe "no-JS fallback: uploading through the file input" do
    it "adds a single file (none => 1)" do
      patch profile_path(profile), params: gallery_params(fixture_file_upload("avatar.png", "image/png"))

      expect(profile.reload.gallery.blobs.map { |blob| blob.filename.to_s }).to contain_exactly("avatar.png")
    end

    it "adds multiple files (none => 2)" do
      uploads = [fixture_file_upload("avatar.png", "image/png"), fixture_file_upload("avatar.png", "image/png")]

      expect do
        patch profile_path(profile), params: gallery_params(*uploads)
      end.to change { profile.reload.gallery.count }.from(0).to(2)
    end
  end
end
