# Katalyst::GOVUK::FormBuilder

Repacking of [GOV.UK Frontend](https://frontend.design-system.service.gov.uk) and
[GOV.UK form components](https://govuk-form-builder.netlify.app) for use in Katalyst projects,
extended with ActiveStorage-backed attachment fields: previews, drag-and-drop, async direct
uploads, and a complete no-JavaScript fallback.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "katalyst-govuk-formbuilder"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install katalyst-govuk-formbuilder

## Usage

Use the GOV.UK form builder for your forms, most simply as the application default:

```ruby
class ApplicationController < ActionController::Base
  default_form_builder GOVUKDesignSystemFormBuilder::FormBuilder
end
```

Add the stylesheet to your default layout:

```erb
<%= stylesheet_link_tag "katalyst/govuk/formbuilder" %>
```

You can also add it to your SASS build:

```scss
@use "katalyst/govuk/formbuilder";
```

### JavaScript

The attachment and file upload fields are Stimulus-powered. Load the gem's
controllers into your Stimulus application:

```js
import { Application } from "@hotwired/stimulus";

const application = Application.start();

import GOVUK from "@katalyst/govuk-formbuilder";
GOVUK.start(application);
```

If you want to keep GOVUK enhancements separate from your main app's Stimulus
application, you can inject the bootstrap JS module into your body instead:

```erb
<%= govuk_formbuilder_init %>
```

You'll need to include the helper to make this method available, which you can add
to your `ApplicationController`:

```ruby
helper Katalyst::GOVUK::FormBuilder::Frontend
```

The snippet marks the page as JavaScript-capable and calls the module's `initAll()`,
but will not survive a new page render (including Turbo navigation). Use this
approach if you are only using GOVUK sparingly.

#### JavaScript dependencies

The formbuilder module imports `@hotwired/stimulus` and `@rails/activestorage`. With
importmaps the gem pins itself and `@rails/activestorage` for you. It does not pin
`@hotwired/stimulus` — your app provides that (`stimulus-rails` does this in a
standard Rails app). If you use jsbundling or similar, you'll need both packages
available at runtime; the wiring is the same `GOVUK.start(application)` shown above,
from your own bundle.

## Attachment fields

`govuk_image_field` and `govuk_document_field` render an upload field for
`has_one_attached` / `has_many_attached` attributes. With JavaScript, files upload
asynchronously as soon as they are chosen or dropped, each showing a preview figure
with progress, retry on failure, and a remove control. Without JavaScript the same
field is a plain file input plus a keep/remove select per attached file — no
functionality is lost, only polish.

```erb
<%= f.govuk_image_field :avatar %>
<%= f.govuk_document_field :cv %>
<%= f.govuk_attachment_field :recording, accept: "audio/*" %>
```

Both fields delegate to `govuk_attachment_field`; they differ only in the mime types
they accept (`config.image_mime_types` / `config.document_mime_types`).

- The attribute's value must be an `ActiveStorage::Attached`; anything else raises
  `ArgumentError` at render. For plain multipart uploads without ActiveStorage, use
  the upstream `govuk_file_field`.
- `multiple` is inferred from the association (`has_many_attached` → multiple), and
  an explicit `multiple:` argument is respected.
- Attachments round-trip as blob signed ids: when validation fails, the re-rendered
  form retains every attachment — stored, direct-uploaded, or pending multipart — so
  a failed submit never loses an upload.
- Removal is always offered. A required attachment should say so with a presence
  validation; the form does not hide removal on its behalf.
- Direct uploads post to `rails_direct_uploads_url` by default. Pass
  `direct_upload_url:` to use a different endpoint, or `direct_upload: false` to
  leave chosen files in the input and submit them as ordinary multipart.
- Fields accept the standard GOV.UK options (`label:`, `hint:`, `caption:`,
  `form_group:`, `before_input:`, `after_input:`) and a block for supplemental
  content rendered inside the form group.

Preview thumbnails are generated lazily through ActiveStorage's representation
route. The transformation is configurable:

```ruby
GOVUKDesignSystemFormBuilder.config.attachment_preview_representation =
  { resize_to_limit: [100, 100] } # the default
```

### Strings and internationalisation

All user-facing strings resolve through Rails i18n under `katalyst.govuk.attachment.*`
(`upload_succeeded`, `upload_failed`, `retry_button`, `file_removed`, `remove_button`,
`remove_button_content`), alongside govuk-frontend's FileUpload strings. Each has a
per-field text option (`upload_succeeded_text`, `upload_failed_text`,
`retry_button_text`, `file_removed_text`, `remove_button_text`,
`remove_button_content_text`, `choose_files_button_text`, `drop_instruction_text`,
`no_file_chosen_text`, `multiple_files_chosen_text`, `entered_drop_zone_text`,
`left_drop_zone_text`). Strings reach the JavaScript enhancement via the field's
`data-i18n.*` attributes, with the locale taken from the closest `lang` attribute.

## Upgrading from 1.x

This major version replaces the image/document field implementations with the
attachment field described above.

- `govuk_image_field` / `govuk_document_field` now require an
  `ActiveStorage::Attached` value and raise `ArgumentError` otherwise. The legacy
  fields rendered a plain enhanced input for other values (e.g. form objects) — for
  those, use `govuk_file_field`.
- The `optional:` argument no longer does anything: removal is always offered, and
  submitting the remove option detaches on save. A required attachment must be
  guarded by a presence validation.
- Dropped files are no longer filtered by mime type on the client. The `accept`
  attribute remains a file-picker courtesy; your model's validations are the
  authority on content.
- `application.load(govuk)` no longer works — the default export is no longer the
  controller definitions array, and Stimulus raises a `TypeError` at boot. Replace it
  with `GOVUK.start(application)` (see JavaScript above), which registers the
  controllers and keeps enhancement running across Turbo visits.
- Remove any `turbo:render` / `turbo:frame-load` re-initialisation wiring —
  enhancement now observes the DOM and owns re-enhancement; repeated calls are
  harmless no-ops.
- Text options on file fields are now honoured by the JavaScript. Previously they
  rendered but were never read, so non-English sites got English announcements.
- Brand (`GOVUKDesignSystemFormBuilder.brand`) now affects CSS classes only:
  Stimulus identifiers, `data-controller`/`data-action` wiring, and events are
  always `govuk-*`. The gem's compiled CSS remains govuk-prefixed — a non-default
  brand presumes a consumer-supplied frontend build.

As a transitional escape hatch, the legacy implementations remain available behind a
flag:

```ruby
GOVUKDesignSystemFormBuilder.config.use_legacy_file_fields = true # default false
```

The flag flips `govuk_image_field` / `govuk_document_field` back to the legacy
elements. It exists to stage a migration, not to stay on: the flag and the legacy
code will be removed together in a subsequent release.

## Extensions

We include some optional extensions for integrating with gems that we (Katalyst)
commonly use. These require additional steps to use.

### Rich text area

`govuk_rich_textarea` renders a Trix editor with GOV.UK form conventions. It
requires ActionText to be set up in your application (`rails action_text:install`),
including its JavaScript (`trix` and `@rails/actiontext`) in your bundle or
importmap.

### Hotwire Combobox

[Hotwire Combobox](https://hotwirecombobox.com) is a promising option for adding asynchronous multi-select inputs to
Rails forms. We're assuming importmaps and Turbo if this option is used.

There's no explicit dependency so if you want to use this input you'll need to add:

```
gem "hotwire_combobox"
```

JS is added by the gem automatically (via importmaps), but you'll need to explicitly load their CSS before ours:

```erb
<%= combobox_style_tag %>
<%= stylesheet_link_tag "katalyst/govuk/formbuilder" %>
```

Or, with Rails dartsass:

```scss
@use "hotwire_combobox";
@use "katalyst/govuk/formbuilder";
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/katalyst/govuk-formbuilder.

## Release

Tag the release version and push to CI.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
