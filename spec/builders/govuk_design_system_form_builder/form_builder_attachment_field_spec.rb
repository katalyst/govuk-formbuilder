# frozen_string_literal: true

# :markup: markdown

require "rails_helper"

# Server-rendered markup for govuk_attachment_field.
#
# Tests:
# * Profile's has_one_attached :avatar: (required)
#   one figure per attached blob (preview, caption, actions)
# * Profile's has_many_attached :gallery: (optional)
#   multiple figures, one per attached blob (preview, caption, actions)
# * Profile's has_one_attached :cv: (optional)
#   one figure per attached blob (caption, actions)
# * Round-tripping multipart form inputs
RSpec.describe GOVUKDesignSystemFormBuilder::FormBuilder do
  let(:builder) { described_class.new(:profile, profile, helper, {}) }
  let(:profile) { create(:profile) }

  def govuk_attachment_field(...)
    Capybara.string(builder.govuk_attachment_field(...).to_s)
  end

  describe "#govuk_attachment_field (avatar / single / required)" do
    subject(:html) { govuk_attachment_field(:avatar) }

    let(:blob) { profile.avatar.blob }

    context "with no attachment" do
      let(:profile) { Profile.new }

      it "renders no attachment figures" do
        expect(html).to have_no_css("figure.govuk-attachment")
      end

      it "renders a single file input inside the wrapper" do
        expect(html).to have_css(".govuk-file-upload-wrapper input[type=file]", count: 1, visible: :all)
      end

      it "does not mark the file input as multiple" do
        expect(html).to have_no_css("input[type=file][multiple]", visible: :all)
      end

      # Exclusivity invariant: initAll enhances data-module="govuk-file-upload"
      # with govuk-frontend's own FileUpload, so an attachment field emitting it
      # would have two implementations fighting over one input.
      it "never emits govuk-frontend's file-upload data-module" do
        expect(html).to have_no_css("[data-module='govuk-file-upload']", visible: :all)
      end
    end

    # The label, caption, hint and form_group configuration must render
    # through the element rather than being dropped; the image and document
    # wrappers forward these options here and rely on them being consumed.
    context "with configuration options" do
      it "renders the hint" do
        html = govuk_attachment_field(:avatar, hint: { text: "Max 5MB" })

        expect(html).to have_css(".govuk-hint", text: "Max 5MB")
      end

      it "describes the input by the hint" do
        html    = govuk_attachment_field(:avatar, hint: { text: "Max 5MB" })
        hint_id = html.find(".govuk-hint", visible: :all)[:id]

        expect(html.find("input[type=file]", visible: :all)["aria-describedby"]).to eq(hint_id)
      end

      it "renders the supplied label text" do
        html = govuk_attachment_field(:avatar, label: { text: "Your photo" })

        expect(html).to have_css("label", text: "Your photo")
      end

      it "renders the supplied caption" do
        html = govuk_attachment_field(:avatar, caption: { text: "Step 1" })

        expect(html).to have_css(".govuk-caption-m", text: "Step 1")
      end

      it "applies form_group options" do
        html = govuk_attachment_field(:avatar, form_group: { class: "extra-group" })

        expect(html).to have_css(".govuk-form-group.extra-group")
      end
    end

    # Each text option renders as a data-i18n.* attribute on the wrapper.
    # The attribute names are the contract's read surface — the JS
    # enhancement configures its strings from these exact names, so a
    # rename here breaks localisation without failing anything else.
    context "with i18n text options" do
      def wrapper(html)
        html.find(".govuk-file-upload-wrapper", visible: :all)
      end

      {
        choose_files_button_text:         "data-i18n.choose-files-button",
        drop_instruction_text:            "data-i18n.drop-instruction",
        no_file_chosen_text:              "data-i18n.no-file-chosen",
        multiple_files_chosen_one_text:   "data-i18n.multiple-files-chosen.one",
        multiple_files_chosen_other_text: "data-i18n.multiple-files-chosen.other",
        entered_drop_zone_text:           "data-i18n.entered-drop-zone",
        left_drop_zone_text:              "data-i18n.left-drop-zone",
        upload_succeeded_text:            "data-i18n.upload-succeeded",
        upload_failed_text:               "data-i18n.upload-failed",
        retry_button_text:                "data-i18n.retry-button",
        file_removed_text:                "data-i18n.file-removed",
        remove_button_text:               "data-i18n.remove-button",
        remove_button_content_text:       "data-i18n.remove-button-content",
      }.each do |option, attribute|
        it "renders #{option} as #{attribute}" do
          html = govuk_attachment_field(:avatar, option => "Custom text")

          expect(wrapper(html)[attribute]).to eq("Custom text")
        end
      end

      # %{count} is govuk-frontend's interpolation placeholder, passed
      # through verbatim — not a Ruby format token.
      # rubocop:disable Style/FormatStringToken
      it "renders the one form of a multiple_files_chosen_text hash" do
        html = govuk_attachment_field(:avatar, multiple_files_chosen_text: { one: "1 file", other: "%{count} files" })

        expect(wrapper(html)["data-i18n.multiple-files-chosen.one"]).to eq("1 file")
      end

      it "renders the other form of a multiple_files_chosen_text hash" do
        html = govuk_attachment_field(:avatar, multiple_files_chosen_text: { one: "1 file", other: "%{count} files" })

        expect(wrapper(html)["data-i18n.multiple-files-chosen.other"]).to eq("%{count} files")
      end
      # rubocop:enable Style/FormatStringToken

      # With no options the attributes are absent, leaving the strings to
      # the enhancement's own defaults.
      it "renders no i18n data attributes by default" do
        attributes = wrapper(html).native.attribute_nodes.map(&:name)

        expect(attributes.grep(/\Adata-i18n/)).to be_empty
      end
    end

    # The remove strings also render into the server figures, so the option
    # must drive both the data attribute (for client figures) and the
    # trait's own markup — string parity between the two figure sources
    # depends on the shared option.
    # rubocop:disable-next Style/FormatStringToken
    context "with remove control options" do
      subject(:html) do
        govuk_attachment_field(:avatar, remove_button_text: "Bin %{filename}", remove_button_content_text: "🗑")
      end

      it "names the remove option with the interpolated text" do
        expect(html).to have_css(
          "figure.govuk-attachment select option[value='']",
          text:    "Bin avatar.png",
          visible: :all,
        )
      end

      it "labels the remove button with the interpolated text" do
        button = html.find("figure.govuk-attachment .actions button")

        expect(button["aria-label"]).to eq("Bin avatar.png")
      end

      it "renders the configured remove button content" do
        expect(html).to have_css("figure.govuk-attachment .actions button", text: "🗑")
      end
    end

    # The attachment strings live in the gem's locale files
    # (config/locales), so a consuming app localises by adding Rails
    # translations — no JS knowledge needed. A translated string renders
    # into the server figures and onto the data-i18n.* attributes (where
    # the JS reads it); the en defaults render neither, leaving the JS to
    # its bundled mirror of the same table.
    context "with a non-default locale" do
      around do |example|
        # rubocop:disable Style/FormatStringToken -- %{filename} is the i18n placeholder
        I18n.backend.store_translations(:fr, { katalyst: { govuk: { attachment: {
                                          upload_succeeded:      "Téléversement réussi",
                                          remove_button:         "Supprimer %{filename}",
                                          remove_button_content: "Retirer",
                                        } } } })
        # rubocop:enable Style/FormatStringToken
        I18n.with_locale(:fr) { example.run }
      ensure
        I18n.backend.reload!
      end

      it "renders the translation onto the data-i18n attribute" do
        wrapper = html.find(".govuk-file-upload-wrapper", visible: :all)

        expect(wrapper["data-i18n.upload-succeeded"]).to eq("Téléversement réussi")
      end

      it "names the remove option from the translation" do
        expect(html).to have_css(
          "figure.govuk-attachment select option[value='']",
          text:    "Supprimer avatar.png",
          visible: :all,
        )
      end

      it "renders the remove button content from the translation" do
        expect(html).to have_css("figure.govuk-attachment .actions button", text: "Retirer")
      end

      it "prefers an explicit option over the translation" do
        html    = govuk_attachment_field(:avatar, upload_succeeded_text: "Custom text")
        wrapper = html.find(".govuk-file-upload-wrapper", visible: :all)

        expect(wrapper["data-i18n.upload-succeeded"]).to eq("Custom text")
      end
    end

    # Overriding the gem's en strings in the app's own locale files is the
    # same customisation path as any other locale: the override must reach
    # the data-i18n.* attributes, or server-rendered figures show the
    # override while JS-created figures and announcements fall back to the
    # gem's bundled defaults — a mixed UI.
    context "with an app-level en override" do
      around do |example|
        # The backend loads locale files lazily on first lookup, clobbering
        # anything stored beforehand — initialise it first so the override
        # merges over the gem's en table, as an app's locale file would.
        I18n.backend.translations(do_init: true)
        I18n.backend.store_translations(:en, { katalyst: { govuk: { attachment: {
                                          upload_succeeded:      "All done!",
                                          remove_button_content: "Bin",
                                        } } } })
        example.run
      ensure
        I18n.backend.reload!
      end

      it "renders the override onto the data-i18n attribute" do
        wrapper = html.find(".govuk-file-upload-wrapper", visible: :all)

        expect(wrapper["data-i18n.upload-succeeded"]).to eq("All done!")
      end

      it "renders the override into the server figure" do
        expect(html).to have_css("figure.govuk-attachment .actions button", text: "Bin")
      end
    end

    context "with an attached image" do
      it "renders one figure with preview, caption, and actions, in order" do
        expect(html).to have_css("figure.govuk-attachment > img + figcaption + div.actions", count: 1, visible: :all)
      end

      it "groups the select and remove button in the actions container" do
        expect(html).to have_css("figure.govuk-attachment .actions > select + button", visible: :all)
      end

      it "does not process the preview variant at render time" do
        expect { html }.not_to change(ActiveStorage::VariantRecord, :count)
      end

      it "captions the figure with the filename" do
        expect(html).to have_css("figure.govuk-attachment figcaption .filename", text: "avatar.png")
      end

      it "captions the figure with the human file size" do
        expect(html).to have_css("figure.govuk-attachment figcaption .size", text: /\A[\d.]+ (Bytes|KB|MB)\z/)
      end

      it "selects the current file, labelled with its filename" do
        expect(html).to have_css(
          "figure.govuk-attachment select option[selected][value='#{blob.signed_id}']",
          text:    "avatar.png",
          visible: :all,
        )
      end

      it "offers a remove option with a blank value naming the file" do
        expect(html).to have_css(
          "figure.govuk-attachment select option[value='']",
          text:    "Remove avatar.png",
          visible: :all,
        )
      end

      it "inputs a hidden input to track removes" do
        expect(html).to have_css(".govuk-file-upload-wrapper input[type=hidden]", count: 1, visible: :all)
      end

      it "renders the blank keeper first, before the other input(s)" do
        types = html.all("[name='profile[avatar]']", visible: :all).map do |node|
          "#{node.tag_name}[type=#{node['type']}]"
        end

        expect(types).to eq(%w[input[type=hidden] select[type=] input[type=file]])
      end

      it "names the select for scalar assignment" do
        select = html.find("figure.govuk-attachment select", visible: :all)

        expect(select["name"]).to eq("profile[avatar]")
      end

      it "gives the select a unique per-blob id" do
        select = html.find("figure.govuk-attachment select", visible: :all)

        expect(select["id"]).to eq(builder.field_id(:avatar, :attachment, blob.id, :input))
      end

      # Hiding the select is CSS-gated on .govuk-frontend-supported so that
      # without JavaScript it stays the visible control.
      it "does not hide the select in markup" do
        expect(html).to have_no_css("figure.govuk-attachment select.govuk-visually-hidden", visible: :all)
      end

      it "renders a remove button wired to the attachment controller" do
        expect(html).to have_css("figure.govuk-attachment .actions button[data-action='govuk-attachment#destroy']")
      end

      it "labels the remove button with the filename" do
        button = html.find("figure.govuk-attachment .actions button")

        expect(button["aria-label"]).to eq("Remove avatar.png")
      end

      it "stops the remove button from submitting the form" do
        button = html.find("figure.govuk-attachment .actions button")

        expect(button["type"]).to eq("button")
      end

      it "styles the remove button as a secondary govuk button" do
        button = html.find("figure.govuk-attachment .actions button")

        expect(button[:class].split).to include("govuk-button", "govuk-button--secondary", "govuk-attachment__remove")
      end

      it "connects the remove button to govuk-frontend's button behaviour" do
        button = html.find("figure.govuk-attachment .actions button")

        expect(button["data-module"]).to eq("govuk-button")
      end

      it "renders Remove as the default remove button content" do
        button = html.find("figure.govuk-attachment .actions button")

        expect(button.text).to eq("Remove")
      end

      it "hides the preview image from assistive technology" do
        expect(html.find("figure.govuk-attachment img")["alt"]).to eq("")
      end

      it "labels the figure with its filename" do
        figure = html.find("figure.govuk-attachment")

        expect(figure["aria-labelledby"]).to eq(builder.field_id(:avatar, :attachment, blob.id, :filename))
      end

      it "gives the filename span the id the figure's label references" do
        filename_id = builder.field_id(:avatar, :attachment, blob.id, :filename)

        expect(html).to have_css("figure.govuk-attachment figcaption .filename[id='#{filename_id}']")
      end

      it "makes the caption a polite live region so status changes are announced" do
        expect(html.find("figure.govuk-attachment figcaption")["aria-live"]).to eq("polite")
      end

      it "announces the whole caption atomically, so announcements name the file" do
        expect(html.find("figure.govuk-attachment figcaption")["aria-atomic"]).to eq("true")
      end

      it "reserves an empty status span in the caption for upload announcements" do
        expect(html.find("figure.govuk-attachment figcaption .status").text).to eq("")
      end

      it "gives the select an accessible name that includes the filename" do
        select      = html.find("figure.govuk-attachment select", visible: :all)
        referenced  = select["aria-labelledby"].to_s.split.flat_map { |id| html.all("[id='#{id}']").map(&:text) }
        label_texts = html.all("label[for='#{select['id']}']", visible: :all).map(&:text)

        expect([select["aria-label"], *referenced, *label_texts].compact.join(" ")).to include("avatar.png")
      end
    end

    # Brand follows CSS classes only: a rebranding consumer replaces the
    # stylesheet, but the JS ships with the gem and registers fixed govuk
    # controller identifiers — behavioural wiring stays govuk whatever the
    # brand.
    context "with a non-default brand" do
      around do |example|
        GOVUKDesignSystemFormBuilder.brand = "defra"
        example.run
      ensure
        GOVUKDesignSystemFormBuilder.brand = "govuk"
      end

      it "prefixes the figure class with the brand" do
        expect(html).to have_css("figure.defra-attachment", visible: :all)
      end

      it "prefixes the wrapper class with the brand" do
        expect(html).to have_css(".defra-file-upload-wrapper", visible: :all)
      end

      it "prefixes the remove button classes with the brand" do
        expect(html).to have_css(
          ".defra-attachment .actions button.defra-button.defra-button--secondary.defra-attachment__remove",
          visible: :all,
        )
      end

      it "connects the figure to the attachment controller" do
        expect(html).to have_css("figure.defra-attachment[data-controller='govuk-attachment']", visible: :all)
      end

      it "connects the wrapper to the file-upload controller" do
        expect(html).to have_css(".defra-file-upload-wrapper[data-controller='govuk-file-upload']", visible: :all)
      end

      it "keeps the remove action on the govuk identifier" do
        expect(html).to have_css("button[data-action='govuk-attachment#destroy']", visible: :all)
      end
    end

    # The preview URL is lazy — the variant is processed when the browser
    # requests it, so rendering the form never touches the blob's bytes and
    # a blob that can't be processed costs a broken image, not an error.
    context "with an attached image whose bytes are missing" do
      before { blob.service.delete(blob.key) }

      it "renders the figure" do
        expect(html).to have_css("figure.govuk-attachment .filename", text: "avatar.png")
      end

      it "renders the preview, leaving the failure to the image request" do
        expect(html.find("figure.govuk-attachment img")[:src]).to be_present
      end

      it "keeps the blob's signed id as the keep option" do
        expect(html.find("figure.govuk-attachment select option[selected]", visible: :all).value)
          .to eq(blob.signed_id)
      end
    end

    context "with a non-image attachment" do
      before do
        profile.avatar.attach(
          io:           StringIO.new("not an image"),
          filename:     "notes.txt",
          content_type: "text/plain",
        )
      end

      it "renders the figure with caption and actions adjacent" do
        expect(html).to have_css("figure.govuk-attachment > figcaption + div.actions", visible: :all)
      end

      it "omits the preview image" do
        expect(html).to have_no_css("figure.govuk-attachment img")
      end
    end

    describe "#direct_upload_url" do
      it "adds data-direct-upload-url by default" do
        input = html.find("input[type=file]", visible: :all)

        expect(input["data-direct-upload-url"]).to eq(helper.rails_direct_uploads_url)
      end

      it "respects direct_upload: false" do
        html = govuk_attachment_field(:avatar, direct_upload: false)

        expect(html).to have_css("input[type=file]:not([data-direct-upload-url])", visible: :all)
      end

      it "still renders the attachment figure when direct_upload is false" do
        html = govuk_attachment_field(:avatar, direct_upload: false)

        expect(html).to have_css("figure.govuk-attachment > img + figcaption + div.actions", visible: :all)
      end

      it "uses direct_upload_url when provided" do
        html  = govuk_attachment_field(:avatar, direct_upload_url: "/override")
        input = html.find("input[type=file]", visible: :all)

        expect(input["data-direct-upload-url"]).to eq("/override")
      end

      it "uses direct_upload_url from form builder when overridden (i.e. Koi admin)" do
        builder.instance_eval do
          def direct_upload_url
            "/extend"
          end
        end

        input = html.find("input[type=file]", visible: :all)

        expect(input["data-direct-upload-url"]).to eq("/extend")
      end

      it "resolves direct-upload-url through main_app" do
        allow(helper).to receive(:respond_to?).and_call_original
        allow(helper).to receive(:respond_to?).with(:rails_direct_uploads_url).and_return(false)

        input = html.find("input[type=file]", visible: :all)

        expect(input["data-direct-upload-url"]).to eq(helper.main_app.rails_direct_uploads_url)
      end

      it "does not set data-direct-upload-url when no direct-upload route is available" do
        allow(helper).to receive(:respond_to?).and_call_original
        allow(helper).to receive(:respond_to?).with(:rails_direct_uploads_url).and_return(false)
        allow(helper).to receive(:main_app).and_return(Object.new)

        expect(html).to have_css("input[type=file]:not([data-direct-upload-url])", visible: :all)
      end
    end

    # ActiveStorage's representation route lives in the application's route
    # set, so an engine-mounted form must resolve the preview URL through
    # main_app — the same resolution direct_upload_url uses.
    describe "preview URL resolution" do
      let(:representation) { blob.representation(resize_to_fill: [256, 256]) }

      it "renders the preview from the representation route" do
        expect(html.find("figure.govuk-attachment img")[:src])
          .to eq(helper.rails_representation_url(representation))
      end

      it "renders the preview from the configured representation" do
        config                                   = GOVUKDesignSystemFormBuilder.config
        original                                 = config.attachment_preview_representation
        config.attachment_preview_representation = { resize_to_limit: [50, 50] }

        expect(html.find("figure.govuk-attachment img")[:src])
          .to eq(helper.rails_representation_url(blob.representation(resize_to_limit: [50, 50])))
      ensure
        config.attachment_preview_representation = original
      end

      it "resolves the preview URL through main_app" do
        allow(helper).to receive(:respond_to?).and_call_original
        allow(helper).to receive(:respond_to?).with(:rails_representation_url).and_return(false)

        expect(html.find("figure.govuk-attachment img")[:src])
          .to eq(helper.main_app.rails_representation_url(representation))
      end

      it "renders no preview when no representation route is available" do
        allow(helper).to receive(:respond_to?).and_call_original
        allow(helper).to receive(:respond_to?).with(:rails_representation_url).and_return(false)
        allow(helper).to receive(:main_app).and_return(Object.new)

        expect(html).to have_no_css("figure.govuk-attachment img")
      end
    end

    context "with an unpersisted multipart upload" do
      before do
        profile.avatar = Rack::Test::UploadedFile.new(file_fixture("avatar.png"), "image/png")
      end

      def pending_blob
        profile.attachment_changes["avatar"].blob
      end

      it "persists the pending blob" do
        expect { html }.to change(pending_blob, :persisted?).to(true)
      end

      it "uploads the bytes" do
        html

        expect(pending_blob.service.exist?(pending_blob.key)).to be(true)
      end

      it "renders the preview from the uploaded bytes" do
        expect(html.find("figure.govuk-attachment img")[:src]).to be_present
      end

      it "renders the persisted blob's signed id as the keep option" do
        expect(html.find("figure.govuk-attachment select option[selected]", visible: :all).value)
          .to eq(pending_blob.signed_id)
      end
    end

    context "with a pending change whose blob is already persisted" do
      # A direct upload arrives as a signed id: the blob already exists with
      # bytes. Non-representable content keeps variant processing out of the
      # render, so any upload call could only come from a wrongful re-persist.
      let(:blob) do
        ActiveStorage::Blob.create_and_upload!(
          io:           StringIO.new("plain text"),
          filename:     "notes.txt",
          content_type: "text/plain",
        )
      end

      before { profile.avatar = blob.signed_id }

      it "does not upload again" do
        allow(ActiveStorage::Blob.service).to receive(:upload)

        html

        expect(ActiveStorage::Blob.service).not_to have_received(:upload)
      end

      it "renders the figure" do
        expect(html).to have_css("figure.govuk-attachment .filename", text: "notes.txt")
      end
    end

    context "when persisting the pending blob fails" do
      before do
        profile.avatar = Rack::Test::UploadedFile.new(file_fixture("avatar.png"), "image/png")
        allow(ActiveStorage::Blob.service).to receive(:upload).and_raise(ActiveStorage::IntegrityError)
      end

      it "drops the figure rather than failing the render" do
        expect(html).to have_no_css("figure.govuk-attachment")
      end

      it "still renders the file input so the user can re-choose" do
        expect(html).to have_field("profile[avatar]", type: :file, visible: :all)
      end

      it "leaves no half-persisted blob behind" do
        html

        expect(profile.attachment_changes["avatar"].blob).not_to be_persisted
      end

      # ActiveStorage's log subscriber only reports successful service calls
      # (it ignores the exception payload), so once the field swallows the
      # error, this warning is the only record that a user's file was dropped.
      it "logs the dropped upload" do
        allow(Rails.logger).to receive(:warn)

        html

        expect(Rails.logger).to have_received(:warn)
                                  .with(include("avatar").and(include("ActiveStorage::IntegrityError")))
      end
    end

    context "when the pending upload's tempfile has vanished before render" do
      before do
        profile.avatar = Rack::Test::UploadedFile.new(file_fixture("avatar.png"), "image/png")
        File.unlink(profile.attachment_changes["avatar"].attachable.path)
      end

      it "drops the figure rather than failing the render" do
        expect(html).to have_no_css("figure.govuk-attachment")
      end

      it "logs the dropped upload" do
        allow(Rails.logger).to receive(:warn)

        html

        expect(Rails.logger).to have_received(:warn)
                                  .with(include("avatar").and(include("Errno::ENOENT")))
      end
    end

    context "with a mixed gallery of a persisted signed id and a multipart upload" do
      let(:persisted) do
        ActiveStorage::Blob.create_and_upload!(
          io:           File.open(file_fixture("avatar.png")),
          filename:     "persisted.png",
          content_type: "image/png",
        )
      end

      before do
        profile.gallery = [
          persisted.signed_id,
          Rack::Test::UploadedFile.new(file_fixture("avatar.png").open, "image/png",
                                       original_filename: "fresh.png"),
        ]
      end

      def render_gallery_field
        Capybara.string(builder.govuk_attachment_field(:gallery).to_s)
      end

      it "persists every pending blob in the change" do
        render_gallery_field

        expect(profile.attachment_changes["gallery"].blobs).to all(be_persisted)
      end

      it "renders a figure for each entry" do
        html = render_gallery_field

        expect(html.all("figure.govuk-attachment .filename").map(&:text))
          .to contain_exactly("persisted.png", "fresh.png")
      end
    end
  end

  describe "#govuk_attachment_field (gallery / multiple)" do
    subject(:html) { govuk_attachment_field(:gallery) }

    context "with no attachments" do
      let(:profile) { Profile.new }

      it "renders no attachment figures" do
        expect(html).to have_no_css("figure.govuk-attachment")
      end

      it "infers multiple from the has_many_attached reflection" do
        expect(html).to have_css("input[type=file][multiple]", visible: :all)
      end

      it "renders a multiple file input when multiple is passed explicitly" do
        html = govuk_attachment_field(:gallery, multiple: true)

        expect(html).to have_css("input[type=file][multiple]", visible: :all)
      end

      it "renders without multiple file input when multiple is passed explicitly" do
        html = govuk_attachment_field(:gallery, multiple: false)

        expect(html).to have_css("input[type=file]:not([multiple])", visible: :all)
      end
    end

    context "with several attached images" do
      before do
        %w[first.png second.png].each do |filename|
          profile.gallery.attach(
            io:           File.open(file_fixture("avatar.png")),
            filename:,
            content_type: "image/png",
          )
        end
      end

      it "renders one figure per attached file, in attachment order" do
        expect(html.all("figure.govuk-attachment .filename").map(&:text)).to eq(%w[first.png second.png])
      end

      it "round-trips each attachment via its own array-named select" do
        profile.gallery.blobs.each do |blob|
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

        expect(ids).to eq(profile.gallery.blobs.map { |blob| builder.field_id(:gallery, :attachment, blob.id, :input) })
      end

      it "renders the blank keeper first, before the other input(s)" do
        types = html.all("[name='profile[gallery][]']", visible: :all).map do |node|
          "#{node.tag_name}[type=#{node['type']}]"
        end

        expect(types).to eq(%w[input[type=hidden] select[type=] select[type=] input[type=file]])
      end
    end
  end

  # cv (optional has_one, PDF) renders the same markup as avatar (required
  # has_one, image) — PDFs are representable wherever a previewer (poppler)
  # is available, so even the preview appears; these examples pin only the
  # attribute's own scalar round-trip.
  describe "#govuk_attachment_field (cv / single / optional)" do
    subject(:html) { govuk_attachment_field(:cv) }

    context "with an attached file" do
      before do
        profile.cv.attach(
          io:           File.open(file_fixture("cv.pdf")),
          filename:     "cv.pdf",
          content_type: "application/pdf",
        )
      end

      let(:blob) { profile.cv.blob }

      it "renders one figure with caption, and actions, in order" do
        expect(html).to have_css("figure.govuk-attachment > figcaption + div.actions", count: 1, visible: :all)
      end

      it "selects the current file, labelled with its filename" do
        expect(html).to have_css(
          "figure.govuk-attachment select option[selected][value='#{blob.signed_id}']",
          text:    "cv.pdf",
          visible: :all,
        )
      end

      it "names the select for scalar assignment" do
        select = html.find("figure.govuk-attachment select", visible: :all)

        expect(select["name"]).to eq("profile[cv]")
      end
    end
  end

  # The field requires an ActiveStorage::Attached value: a plain attribute
  # (e.g. a form object's attr_accessor) has no signed ids to round-trip, so
  # the field cannot edit or re-render it — plain uploads stay with
  # govuk_file_field. Failing fast beats a broken editing experience.
  describe "#govuk_attachment_field (non-ActiveStorage attribute)" do
    let(:builder) { described_class.new(:form, form_object, helper, {}) }
    let(:form_object) { NonStorageForm.new }

    before do
      stub_const("NonStorageForm", Class.new do
        include ActiveModel::Model

        attr_accessor :upload
      end)
    end

    it "rejects the attribute with an error naming it" do
      expect { builder.govuk_attachment_field(:upload) }
        .to raise_error(ArgumentError, /upload/)
    end
  end
end
