# Attachment field — specification

`govuk_attachment_field` (and its `govuk_image_field` / `govuk_document_field`
wrappers) renders an ActiveStorage-backed file upload with previews, async
direct upload, and a full no-JavaScript fallback.

## Design

1. **The `<select>` is the source of truth.** Each attached blob renders a
   per-blob `<select>` with a *keep* option (value = blob signed id, label =
   filename, selected) and a *remove* option (blank value). The form always
   round-trips attachments as signed ids — never re-uploaded bytes — and the
   same control makes attachments editable without JavaScript: there is no
   `_destroy` mechanism, and no hidden input ever carries a signed id (the
   only hidden input is §5's blank keeper).
2. **We own the drop zone.** The field replaces govuk-frontend's FileUpload
   JS behaviourally (reusing its markup conventions and i18n strings) rather
   than running it: that component derives all of its state — status text,
   empty styling, drop capacity — from the input's FileList, which this
   field clears after dispatching uploads, and it initialises once with no
   teardown, which doesn't compose with the Stimulus/Turbo lifecycle.
   Parity with `file-upload.mjs` is pinned by the drop-zone parity system
   spec, which runs govuk-frontend's own enhancement as the live reference
   and diffs the two drop zones in canonical form (intended differences
   scrubbed explicitly); purely behavioural differences remain a review
   concern on upstream bumps. Accepted differences: plain errors rather
   than `ElementError`; count strings even for one file (C10 records why);
   our announcements region renders inside the wrapper — scoped finds and
   morph re-enhancement keep it — where govuk-frontend's sits after the
   drop zone; and our drop listeners bind to the wrapper where upstream's
   bind to its button — equivalent zones, since upstream's button is its
   whole drop zone while ours shares the wrapper with figures.
   govuk-frontend's own component stays supported for plain file fields
   (`initAll` initialises `data-module="govuk-file-upload"`), so the
   **exclusivity invariant** is critical: every file input is enhanced by
   exactly one implementation — attachment fields render the Stimulus
   `data-controller` and must never emit `data-module="govuk-file-upload"`;
   plain govuk file fields the reverse.
3. **Uploads go through ActiveStorage's `DirectUploadController`** (public
   export of `activestorage.esm.js`), subclassed so success writes the signed
   id into the figure's select option. This inherits the
   `direct-upload:start/progress/end` event lifecycle and error dispatch,
   which drive the figure's progress display and error states.
   `data-direct-upload-url` lives on the file input, where the controller
   reads it.
4. **Enhancement fails open.** The server-rendered form is complete and
   functional on its own; JavaScript only takes ownership of a selection
   when a figure's controller *claims* it. Selection renders one figure per
   file, each carrying its `File` object; when the figure's controller
   connects — and only when it can deliver an upload
   (`data-direct-upload-url` present on the input) — it claims the file:
   it announces `govuk:upload` on the input and starts the upload, and the
   file-upload controller releases the claimed file (matched by object
   identity — names can collide) from the FileList. Claiming is what
   prevents ActiveStorage's submit-time auto-upload from sending the same
   bytes again. Unclaimed files stay in the input and submit as ordinary
   multipart, so the fallback holds by construction: a controller that is
   absent, broken, or never connects claims nothing. Editing the FileList
   programmatically (`DataTransfer` reassignment) fires no `change` event,
   so releasing a file cannot re-trigger selection handling.
5. **Param shape.** `name[]` for `has_many_attached` (one entry per select),
   scalar `name` for `has_one_attached` — in both cases led by a blank
   keeper the field renders (hidden input, same name, blank value, no id),
   suppressing Rails' auto-blank for `file_field multiple: true`
   (`include_hidden: false`) so one input the field owns plays that role
   everywhere: the attribute always submits, even when a
   removed figure has taken its select away. Scalar last-wins means any
   select or multipart part overrides the keeper. Assignment is
   replace-on-assign: the
   submitted set *is* the resulting set, a lone blank clears, and one array
   freely mixes blanks, signed ids, and multipart uploads.
6. **The field makes pending blobs renderable.** A failed save re-renders
   with attachment changes still pending, so generating the field persists
   any unpersisted blob (record + bytes): its figure renders and its signed
   id round-trips exactly like a direct upload — a failed submit never
   loses an upload. Persistence is idempotent (already-persisted blobs are
   never re-persisted, so controller-level persistence composes and leaves
   the field nothing to do), and rendering never touches a blob's bytes:
   preview URLs are lazy, so the variant is processed when the browser
   requests the image, and a blob whose bytes are missing or unprocessable
   (out-of-band purge, storage loss, mirror lag, bad content) costs a
   broken image in that figure — never a failed render, keep option intact.
   Validating attachment content is the model's responsibility, not the
   form's.
   Persisted-unattached blobs are the same GC category direct upload
   already creates; purging them stays the consumer's existing
   responsibility.
7. **JS-injected UI is JS-only.** The pseudo button, its status region, and
   the announcements region are injected by the controller and never
   server-rendered: without JavaScript the browser-native file input is the
   whole experience. A Turbo morph refresh therefore strips the injected UI
   and any other JS-set state (including the page's support marker), and it
   may either recreate the drop zone (lifecycle events fire) or patch it in
   place (no events at all) — so recovery is driven by observing the DOM,
   not framework events: losing a marker or the injected UI *is* the morph
   signal. After any morph, both levels recover: the support marker is
   restored (before paint) and the field re-enhances — injected UI rebuilt,
   transient client state discarded (FileList cleared, unclaimed previews
   dropped), count matching the server-rendered figures (C11).

Form group structure (top to bottom):

```
form group (data-controller for the drop zone)
  label
  hint
  error message(s)
  before_input content
  attachment figure(s), one per blob (0..1 for has_one, 0..n for has_many)
  pseudo upload button + drop region ("Choose files" / drop instruction)
  native file input (hidden when JS is active; data-direct-upload-url)
  after_input content
  supplemental content (block content, e.g. alt text / caption fields)
```

- Without JS the native file input is a plain visible input; with JS it is
  hidden and fronted by the pseudo button, which triggers the browser file
  picker. The drop target is the whole drop zone — the wrapper element,
  figures included — not just the pseudo button (a file dragged anywhere
  over the field can be dropped), and not the form group around it: a
  valid drag over the wrapper adds `--dragging` to the button and is
  announced through a JS-injected visually-hidden assertive region
  (`.govuk-file-upload-announcements`), and a drop fills the input exactly
  as choosing files does. A drop is accepted only within the input's
  capacity (one file unless `multiple`). The announcements region carries
  every *event* announcement — drag enter/leave and removals — while the
  button's polite status region carries only *state* (the file count). The
  button is wired to the field's existing accessibility affordances: it takes
  the input's original id (so the label's `for` labels it), the label is given
  a matching id for the button's `aria-labelledby`, the input's
  `aria-describedby` (hint/error) is copied onto it, and its `disabled` state
  is mirrored from the input (F4, F5, C12).
- Each attachment figure: preview (`img`, when representable), `figcaption`
  (filename, human size, and an empty status span), then an actions
  container (`div.actions`) holding the keep/remove `<select>` and a remove
  `<button>` (`type="button"`, visible text "Remove" by default — never a
  bare glyph — accessible name "Remove <filename>"); upload state via
  `data-state`. On upload failure a retry `<button>` (`type="button"`,
  "Try again", accessible name naming the file) is injected at the head of
  the actions container and removed again when an attempt starts; it is
  never server-rendered — failed figures only exist client-side (C3).
  Figure buttons carry govuk-frontend's button markup — `govuk-button
  govuk-button--secondary` plus a component class
  (`govuk-attachment__remove` / `__retry`) and a fixed
  `data-module="govuk-button"`, mirroring the password-input toggle —
  leaning on the gem's styling rather than custom button treatments. Markup ships both controls unhidden; CSS scoped to
  `.govuk-frontend-supported` (set on `<body>` by the
  `govuk_formbuilder_init` body-end snippet only when the browser can run
  the bundle, and maintained across morphs by its observers) swaps them:
  without
  JavaScript the select is the visible control and the button is hidden,
  with JavaScript the button is the figure's only interactive control and
  the select is `display: none` — it still submits its value but is out of
  the tab order and the accessibility tree, so each figure presents exactly
  one control. The figure, its select, and the upload progress bar are
  labelled by the caption's filename span (`aria-labelledby` to its id):
  accessible names carry stable identity — the filename alone, matching
  govuk-frontend's own single-file convention, with no punctuation needs —
  never size or upload status. Status is state: it enters no name and no
  `aria-describedby` (focus re-reads descriptions, which would reinstate
  the residue). The caption is a polite atomic live region: JS writes
  upload status into the status span, and the atomic announcement reads
  the whole caption so the user hears which file the status belongs to.
  The status is not cleaned up afterwards, deliberately: it stays visible
  — useful context until the form is submitted — without entering any
  accessible name; the announcements region likewise keeps its last event,
  which live-region semantics never re-announce but the reading cursor can
  still reach — a user who missed the message can go back and re-read it.
- Client-inserted figures and server-rendered figures are structurally
  identical, so re-renders and JS insertions are interchangeable. The JS
  template (`createAttachment`) and the server trait are updated together
  rather than generated from a shared template, and the markup-parity
  system spec diffs the two figures' canonical forms so drift fails a test
  (C6).

### Builder syntax (reference shape)

```ruby
def govuk_image_field(attribute_name,
                      label: {}, hint: {}, form_group: {},
                      mime_types: config.image_mime_types,
                      direct_upload: true,        # false renders no direct-upload-url
                      direct_upload_url: ...,     # explicit endpoint override
                      before_input: nil, after_input: nil,
                      &supplemental_content)
```

`direct_upload_url` defaults through a builder method of the same name
(`rails_direct_uploads_url`, falling back to `main_app`, omitted when no route
is available), so engine builders (e.g. Koi admin) override the method to
point every field at their own endpoint. `direct_upload: false` opts a single
field out of async upload without changing the attachment markup.
Preview URLs resolve the same way: `attachment_preview_url` (a public builder
method) resolves the representation route with the same `main_app` fallback
and returns nil when no route is available — the figure then renders without
a preview — so engine builders can override preview resolution too. The
preview transformation is configurable
(`config.attachment_preview_representation`); the default fits the image
within 100×100 preserving aspect, never upscaling
(`resize_to_limit`). Previews are contained, not cropped: the whole image
shows, letterboxed by CSS (`object-fit: contain` in a square preview box)
rather than by baked-in padding — variants carry no background bars, and
client-inserted previews get the same treatment so framing doesn't change
when a figure round-trips.

`multiple` is inferred from the attribute's ActiveStorage reflection
(`has_many_attached` → true), and an explicit `multiple:` argument is
respected. The attribute's value must be an `ActiveStorage::Attached`;
anything else raises `ArgumentError` at render — the field is built from
blob signed ids end to end (see the non-ActiveStorage rabbit hole; plain
uploads use `govuk_file_field`). `govuk_document_field` is the same shape
with document mime types; both delegate to `govuk_attachment_field`.

## Acceptance criteria

Each criterion names the test type that verifies it.

### A. Server-rendered markup (builder specs)

- **A1** An attached blob renders a `figure.govuk-attachment` containing, in
  order: preview (`img` for representable blobs, omitted otherwise), a
  `figcaption` with filename and human file size, and the keep/remove select.
- **A2** The select's first option is the current file (label = filename,
  value = signed id, selected); the second option removes it (blank value,
  label includes the filename, e.g. "Remove avatar.png").
- **A3** Select `name` is `object[attr][]` when the attribute is
  `has_many_attached`, `object[attr]` when `has_one_attached`; ids are unique
  per blob (`field_id(attr, :attachment, blob.id, :input)` convention).
- **A4** With no attachments, no `figure.govuk-attachment` renders.
- **A5** The file input carries `accept` from `mime_types`; `multiple` when
  explicitly passed, else inferred from the attribute (`has_many_attached` →
  true); and `data-direct-upload-url` resolved from
  `rails_direct_uploads_url` (with `main_app` fallback; attribute omitted when
  the route is unavailable or `direct_upload: false` is passed — neither
  degrades the attachment markup).
- **A6** Preview `img` has `alt=""`; the select has an accessible name that
  includes the filename. Accessible names are built from the filename span
  alone — identity, not state: the size and status spans stay visible (and
  inside the caption's atomic announcements) without entering any name.
- **A7** Non-image blobs (e.g. PDF) render figure, caption and select without
  an `img` and without error.
- **A8** The field renders exactly one blank hidden input (the keeper),
  before any figure's select — scalar and `has_many` alike (Rails'
  auto-blank is suppressed, so there is never a second blank).
  Keeper-before-selects order is load-bearing for scalars: last-wins means
  a trailing blank would detach every kept file.

### B. No-JS editing (request specs)

- **B1** Add one file via multipart file input: none → 1.
- **B2** Add multiple files via multipart input: none → N.
- **B3** Keep: submitting the existing signed id retains the attachment (1 → 1).
- **B4** Remove: submitting blank for that blob detaches it (1 → none); the
  lone keeper blank clears an emptied `has_many`.
- **B5** Swap: submitting a new signed id without the old one replaces (1 → 1).
- **B6** Mixed arrays (blank + signed ids + multipart files) attach correctly.

### C. JS-enhanced upload (system specs)

- **C1** Choosing/dropping a file immediately inserts a preview figure inside
  the field showing filename (and image thumbnail when applicable) in an
  *uploading* state (`data-state="uploading"` on the figure).
- **C2** On direct-upload success the figure reaches
  `data-state="upload-successful"` and its select's first option value equals
  the new blob's signed id.
- **C3** On direct-upload failure the figure reaches `data-state="upload-failed"`,
  shows a human-readable message (not raw DirectUpload text), and offers
  removal and retry. Retry re-attempts the direct upload with the file the
  figure holds (failed figures are always client-inserted — a failed upload
  never gains a signed id, so the server never renders one — and client
  figures carry their `File`), re-entering the standard uploading lifecycle.
  A failed figure never submits a signed id. The figure's message
  is the failure UI: `direct-upload:error` is dispatched without ActiveStorage's
  `window.alert(error)` fallback (the raw text as a native dialog). The event
  is notification only — consumer listeners may observe it, but cancelling it
  does not alter the failure handling; nothing may convert a failed upload
  into an `upload-successful` figure, whose blank select would silently drop
  the file. Activating retry removes the retry control (re-entry to
  `uploading`), so focus must move deliberately — to a control of the same
  figure (the remove button is the only one while uploading) — never
  dropped to the bare page.
- **C4** The FileList is empty after uploads are dispatched (no double
  attach when the form is submitted).
- **C5** For `has_one_attached`, uploading a replacement supersedes the
  existing figure: the new figure appends after the old one, both post the
  same scalar param and the last select wins, and CSS (scoped to
  non-`multiple` drop zones) shows only the last figure. The superseded
  figure stays in the DOM, so removing the replacement reveals it again —
  replace is freely revertable before submit. Submitting before the
  replacement's upload completes (or after it fails) follows the same rule
  — the submitted set is the truth: the replacement has no signed id yet,
  so its blank wins and an optional attachment detaches, while a required
  one fails its presence validation and re-renders with an error, stored
  file untouched. Presence validation is the guard for attachments that
  must not be lost.
- **C6** Client-inserted markup and server-rendered markup for the same blob
  are structurally identical (same figure/caption/select contract). Pinned
  by the markup-parity system spec: both figures are captured from one live
  page and compared in canonical form — ids tokenised in encounter order
  (the wiring is compared, the values are not), signed ids and URLs
  tokenised, upload lifecycle scrubbed — so drift fails with a line diff.
  The canary is a representable (image) scalar figure; changes to shapes it
  doesn't visit (e.g. non-image figures) must still update the JS template
  and server trait together.
- **C7** When no controller claims a selection (JS absent, failed, or never
  connected), the FileList is left intact and the files submit as ordinary
  multipart (the B path) — enhancement never intercepts what it cannot
  deliver.
- **C8** While uploading, the figure shows a progress bar driven by the
  `direct-upload:progress` events, exposed accessibly (`role="progressbar"`
  with current value; completion announced per F1).
- **C9** When the file input has no `data-direct-upload-url`, the enhanced
  field still operates but starts no uploads and never claims the files —
  they stay in the FileList and submit as ordinary multipart. Preview
  figures still render (blank select values, so nothing double-submits),
  and removing such a figure also releases its file from the FileList.
  Because browsers replace the FileList on re-selection, unclaimed previews
  whose file has left the input are dropped when the selection changes —
  a preview never suggests a file that won't submit.
- **C10** The upload button's status region describes the field's contents
  using govuk-frontend's FileUpload i18n strings: `noFileChosen` ("No file
  chosen") when empty, else `multipleFilesChosen` with the count of
  attachment figures plus any files held in the FileList ("2 files chosen").
  Count strings are used even for a single file ("1 file chosen") — a
  deliberate divergence from govuk-frontend, which shows the filename for
  one file: their status is the only description of the selection, whereas
  here each attachment figure already names its file, so the status repeats
  no filenames. The count updates in place as figures are added (server
  render, upload) and removed; the region carries only this state — event
  announcements such as removals go to the assertive announcements region
  (D4).
- **C11** After a Turbo morph refresh the field still works: the injected
  UI (button, status, announcements region) is rebuilt, transient client
  state is discarded — the FileList cleared, unclaimed previews dropped —
  the count matches the server-rendered figures, and subsequent selections,
  uploads, and removals behave as on first load.
- **C12** The injected button mirrors the file input's `disabled` state: on
  enhancement it is disabled iff the input is, and the drop zone carries
  `govuk-file-upload-wrapper--disabled` (reusing govuk-frontend's disabled
  styling). A `MutationObserver` on the input keeps the button and wrapper in
  step when the input's `disabled` attribute changes at runtime.

### D. Removal (system specs)

- **D1** Each figure offers a remove control whose accessible name includes
  the filename.
- **D2** Removing (JS) removes the figure from the DOM so its value no longer
  submits; the keeper still does, clearing an emptied `has_many` and
  detaching an emptied `has_one` — with or without JS, removal ends in the
  same blank submission (B4).
- **D3** After removal, focus moves to the field's upload button — one
  deliberate destination for every removal, whose focus reading is the
  post-removal summary (its status carries the fresh count) — never lost to
  `<body>`. (Stepping back into the gallery between bulk removals is
  accepted friction; multi-file fields are rare.)
- **D4** Removal is announced to assistive technology, naming the file,
  through the field's assertive announcements region.

### E. Round-trip (system + request specs)

- **E1** Submitting an invalid form re-renders every attachment — persisted,
  direct-uploaded (signed id not yet attached), or a pending multipart
  upload (persisted by the field at render, Design §6) — as server-rendered
  figures whose signed ids round-trip; a failed submit never loses an
  upload.
- **E2** Server-side validation errors render above the input in standard
  GOV.UK error style and appear in the error summary.

### F. Accessibility (system specs / manual audit)

System specs pin announced *content* (region text); what a screen reader
actually voices is verified manually — no scripting surface can observe
it (the AppleScript `last phrase` slot drops transient announcements, and
VoiceOver's caption panel, the only faithful source, is unreachable).
`script/voiceover/` (throwaway tooling, outside the gemspec) OCRs the
caption panel speech-timed for coarse capture.

- **F1** Upload progress and completion are announced via an aria-live region.
- **F2** All controls are keyboard operable; buttons are `type="button"`.
- **F3** Decorative images/icons are hidden from the accessibility tree.
- **F4** The injected button's accessible name resolves: the field label
  (rendered by the form group, outside the drop zone) is given an id and the
  button's `aria-labelledby` references it — along with the button's own
  content — so the label names the button, not a dangling id. The button
  takes the input's original id, so the label's `for` labels it too.
- **F5** The input's `aria-describedby` (its hint and error ids) is copied
  onto the injected button, so the descriptions that applied to the input
  reach the control the user actually operates.
- **F6** Removing a figure announces the removal once, and the focus
  destination is read once with post-removal state — no stale count, no
  repeated reads.
- **F7** Selection and upload outcomes are audible without navigating:
  choosing files announces the updated count on dialog close (a focus
  re-read, "dialog closed", then the count again — matching upstream
  FileUpload's behaviour); a drop announces the count once; an upload's
  outcome announces from the figure's caption, naming the file
  ("<filename> … Uploaded successfully"). Selection deliberately announces
  the count rather than naming each file — the figures name the files.

### G. Internationalisation

- **G1** All user-facing strings (choose files, drop instruction, remove
  option/button labels, upload states, announcements) come from the existing
  i18n options/data mechanism — none hardcoded in JS templates.

### H. Integration & packaging

- **H1** The compiled build treats `@rails/activestorage` and
  `@hotwired/stimulus` as external (rollup `external`), leaving the bare
  import specifiers for the consumer environment to resolve: importmap apps
  inherit the gem's engine pins automatically; bundler apps resolve them
  from their own `node_modules`, guided by the README's
  JavaScript-dependencies notes. `package.json` records the two as
  `peerDependencies` mirroring the `external` list (an in-repo record — the
  package itself is not distributed; the gem is the only artifact).
- **H2** All rendered/injected filenames are escaped (no `innerHTML`
  interpolation of user-controlled strings).
- **H3** The attachment field is the default file field: `govuk_image_field`
  / `govuk_document_field` render it, and no backwards-compatibility shims
  are provided. Ships as a **major version release**; consumers of the
  previous image/document fields adapt their code, guided by the README's
  upgrade guidance and the release PR's notes (no CHANGELOG file is kept —
  release notes are maintained on the PR). The legacy implementations
  remain in the tree behind `config.use_legacy_file_fields` (default
  `false`) through the release as a documented transitional escape hatch —
  the flag flips `govuk_image_field` / `govuk_document_field` back to the
  legacy elements. A subsequent release removes, together and without
  shims: the legacy elements and controllers, the flag,
  `legacy_file_fields_spec`, and the dummy form's `optional:` arguments
  (consumed only by the legacy elements and their spec).

## Implementation constraints

Normative; violating any of these reintroduces a known failure mode.

- The keeper is the only blank: pass `include_hidden: false` to suppress the
  auto-blank Rails emits for `file_field multiple: true`, so exactly one
  blank renders in every case — never two. Its position is load-bearing for
  scalars (it renders before the selects, or last-wins would detach every
  kept file); in the array only its presence matters.
- `blob.signed_id` is the only round-trip token. Render per-blob inputs
  through form-builder methods (`select`, `field_name(attr, multiple:)`,
  `field_id`) — `ActionView::Helpers::Tags::*` are internal and not
  constructible directly. Rails does not disambiguate ids for `[]`-named
  inputs; the per-blob `field_id` suffix is ours to apply.
- One single-`<select>` per blob, never `select multiple:` (wrong UX and
  wrong param semantics).
- Attachment traits must branch on `Attached::One` vs `Attached::Many`
  (`value.blob` does not exist on `Many`).
- Resolve focus targets *before* `element.remove()` — `closest()` on a
  detached node returns null.
- Live-region writes follow the interaction's last focus move. A focus
  change discards pending not-yet-spoken live-region writes; a write
  co-arriving in the same task survives only as VoiceOver batching, not a
  contract screen readers share. So order focus-first, write-after (as
  removal does), or write from handlers that only run after focus settles
  (change, drag enter/leave — the only places govuk-frontend's FileUpload
  writes). Announcement-before-focus would need focus held back for the
  announcement's speech duration — seconds of keystrokes landing on
  `<body>` — rejected.
- Accessible names for repeated per-file controls include the filename;
  prefer visible or visually-hidden text / `aria-labelledby` to the
  filename span over duplicated `aria-label` strings. Thumbnails get `alt=""`; decorative
  icons get `aria-hidden="true"` (never a nameless `role="img"`).
- Filenames are user-controlled: assign via `textContent`/attributes, never
  interpolate into `innerHTML`.
- The selection hand-off event is cancelable; un-cancelled means unhandled —
  leave the FileList intact so the files submit as multipart (Design §4).
- Preview URLs are lazy — render `blob.representation(...)` without
  `.processed`, resolved through `attachment_preview_url` (main_app
  fallback; nil renders the figure without a preview), so form render never
  downloads, transforms, or routes bytes eagerly.
  Render-time processing turned missing bytes or a missing image library
  into a failed render, and serialized variant generation for every figure
  into the request. Missing bytes cost a broken image at request time
  (Design §6). (Mid-upload submits never reach the render: assignment
  identifies the blob by downloading a chunk, and our JS only writes a
  signed id into the select after the byte upload completes.)
- Persist pending blobs upload-first: a blob whose byte upload fails is
  simply never saved, and the render's `persisted?` filter drops it — no
  purge-on-error step (it would run exactly when the service is failing).
  Stranded partial writes are prevented at the service layer (Disk deletes
  its partial write before raising `IntegrityError`; S3 PUTs are atomic).
  Log dropped uploads — ActiveStorage's own instrumentation logs success
  messages even for failed uploads, so nothing else records the drop.
- `app/javascript` is the source; `app/assets/builds` is what browsers run.
  Rebuild before trusting a system test.
- Re-enhancement is driven by MutationObservers, never Turbo events:
  `turbo:load` doesn't fire on morph renders, `turbo:render` listeners are
  registration-order dependent, and a recreated element receives lifecycle
  events instead of morph events. Observers attach to the body/drop-zone
  *element*, so a replace render disposes them with the node it replaces.
  Two enhancement entry points, one registration: `start(application,
  config)` — the primary application.js wiring, and the default export —
  registers the gem's controllers on the given Stimulus application (a
  gem-owned application when omitted; first registration wins) and keeps
  enhancement session-durable by watching `documentElement`, surviving
  body replacement. `initAll(config)` — rendered per body by
  `govuk_formbuilder_init` — is body-scoped with no self-rearming, and
  registers the controllers on the gem-owned application for apps not
  running Stimulus. The two compose deterministically: head modules run
  before the body-end snippet, and registration is first-wins. Legacy
  `application.load(govuk)` throws at boot — loud, never a silent
  double-registration. (The gem-owned application branch is verified
  manually: under first-wins, a host application that registers first —
  as the dummy's does — always claims registration, so no runtime test
  reaches it.)
- The string vocabulary lives twice by design: `config/locales/en.yml` is
  canonical (Rails resolves the strings and renders values onto the
  wrapper's `data-i18n.*` attributes whenever they differ from the gem's
  bundled defaults), and the JS bundle mirrors the defaults for enhancement
  without attributes — keep the two tables in step. The difference check
  reads the bundled table straight from the gem's own locale file, never
  through I18n resolution: resolution absorbs a host app's overrides, and
  an override in any locale — en included — must reach the attributes or
  server-rendered and JS-created figures diverge.
  Inherited keys keep govuk-frontend's names: the `data-i18n.*`
  attribute shapes are the compatibility bar. Nothing diffs the two
  default tables — a drifted default only shows on a field rendered with
  default strings and no attributes — so review both on any vocabulary
  change.
- Brand follows CSS classes only; behavioural wiring is fixed. Stimulus
  identifiers, `data-controller`/`data-action` values, and events are
  always `govuk-*`, while the classes Ruby renders and JS injects — and the
  class-based selectors JS queries — follow the configured brand. Brand
  crosses to JS via the entry points' config (`start(application,
  { brand })` / `initAll({ brand })`; the snippet omits the argument at
  the default brand) and defaults to `govuk`. The gem's compiled CSS stays
  govuk-prefixed: a consumer exercising brand brings their own frontend
  CSS (upstream govuk-frontend JS likewise only matches fixed module
  names, so brand ≠ govuk already presumes a forked frontend).
- Enhancement sweeps overlap by design (marker-restore and arrival sweeps
  visit the same roots in one morph batch) — check `isInitialised` before
  constructing a component; construct-and-catch logs an error per component
  per morph. Re-constructing on morph-retained nodes can duplicate
  listeners; govuk components mostly bind injected elements, so this is
  tolerable — re-check whenever a component joins the sweep. The arrival
  observer runs a full sweep per added element: cheap at the current
  component count, worth revisiting if the list grows.
- Interactive controls never live inside a live region: the caption is
  atomic, so a control there is re-read with every status update and can
  lose focus when the region re-renders. The retry control sits in
  `div.actions`; the failure status text ("Upload failed — try again") is
  what tells a screen-reader user the affordance exists.
- Stimulus connects controllers asynchronously after DOM insertion — events
  dispatched at just-inserted figures must account for this (no bare
  synchronous dispatch).

## Non-goals

- **Client-side upload errors never register in the GOV.UK error summary.**
  The summary is the server-side validation channel (E2); upload failures are
  widget-local by design (C3). This is explicitly undesirable, not deferred.
- **Filename normalisation.** The caption names the file exactly as stored
  — the same name downloads carry — so percent-encoded or otherwise noisy
  stored filenames render (and announce) verbatim. A `%20` in a stored
  name is indistinguishable from a legitimate literal, and browsers and
  direct upload never produce encoded names — they enter via consumer
  ingestion (e.g. URL-derived filenames attached from `io:`). Fix at
  ingestion or by data migration in the consuming app; the field renders
  the truth.

## Rabbit holes

Known traps we are deliberately not entering; each entry names the supported
alternative. Where the alternative is an event we already emit, we do not
build on top of it.

- **Inferring `optional` from model validations.** Deriving the field's
  optionality (e.g. GOV.UK's "(optional)" label convention, remove
  affordances) from `validators_on(:attr)` looks like the `multiple`
  inference — view behaviour from model metadata — but validation reflection
  is unreliable where reflection isn't: presence validators can be
  conditional (`if:`/`unless:`, `on:` contexts) or live in attachment
  validation gems the reflection can't see, and a wrongly-inferred
  "(optional)" label is a content failure, not a cosmetic one. Revisit when
  `optional` drives real behaviour again; until then the supported path is
  an explicit argument from the caller, who knows the form's context.
- **Client-side file validation (mime type, size, dimensions).** The
  `accept` attribute filters the picker as a courtesy and no more: drag/drop
  bypasses it, browsers derive a file's type from its extension, and only
  the server can verify content. Client-side enforcement with error
  messaging would be built on a guess and wrongly reject valid files — the
  server's validation is the authority (E2), and a round-trip that re-renders
  every kept file (E1) is the correction loop. Consumers who want their own
  checks can cancel the selection hand-off event (Design §4) and leave the
  file unclaimed.
- **Submit protection for in-flight uploads.** Submitting mid-upload is
  allowed: the file simply isn't stored, and if that matters the server's
  validation reports it (E2) — the visible `uploading` state and status
  announcements give the user enough feedback to understand what happened.
  This includes a has_one replacement, where the incomplete figure's blank
  supersedes the stored attachment (C5): required fields are protected by
  their presence validation; optional fields detach.
  Blocking or deferring submission drags in disabled-submit state management,
  re-enable-on-error paths, and double-submit interactions; consumers whose
  use case demands it can build it from the `direct-upload:start/end` events
  on the file input.
- **Non-ActiveStorage attachment values.** Rendering the field for e.g. an
  `attr_accessor`-backed form object looks like loose coupling, but
  everything load-bearing is built from blob signed ids: direct upload
  writes one into the select, error round-trips re-render from them (E1),
  and figures need filename, size, content type, and a preview URL. A
  non-AS value gets none of that — direct upload would assign signed-id
  strings only meaningful if the form object consumes them, the keeper
  would assign `""` when nothing is chosen, and a *present* value has no
  figure or editing story without a duck-type interface plus a
  `polymorphic_url`-style preview mechanism. Possible, but a project of its
  own — out of scope. The element raises `ArgumentError` for non-`Attached`
  values; plain multipart uploads without previews use the upstream
  `govuk_file_field`.
- **Sequential upload queueing.** Figures upload concurrently, each
  starting on claim. ActiveStorage's own form-submit flow queues uploads
  one at a time — attractive on a slow uplink, where N concurrent uploads
  all finish late together while a queue completes the first file at ~1/N
  of the total — but queueing drags in queue scope (per field or
  page-wide), dequeue-and-abort teardown for removed figures, a queued
  lifecycle state touching C1/C8's progress contract, and retry
  re-enqueueing. Multiple-file interfaces are rare in practice, and an
  early submit keeps completed files under either model (their signed ids
  are already in their selects), so concurrency ships; revisit if a real
  use case surfaces the slow-uplink problem.
- **Renaming attachments.** `filename` is display metadata on the blob and
  the field round-trips signed ids only, so no rename affordance exists.
  In-place `blob.update(filename:)` mutates persisted, possibly shared
  data outside the form's submit-time-truth model (and public-mode
  services bake Content-Disposition into the object at upload, so it lies
  there anyway). The viable shape — a copy-on-write rename that the
  existing swap semantics absorb — is pitched in
  `doc/pitches/filename-rename.md`; until pursued, renaming is out of
  scope and rename-before-upload belongs to the client, where the name
  rides the blob-creation request.
- **Wrapping govuk-frontend components in Stimulus controllers.** Wrapping
  looks like it would unify enhancement under Stimulus's observer, but
  Stimulus never re-connects a morph-retained element and govuk components
  have no teardown to re-enter through — morph recovery gets worse, not
  better — while consumer-authored `data-module` markup silently stops
  enhancing, diverging from govuk-frontend's documented conventions. The
  supported path is the current `data-module` sweep with our own
  observers; the full analysis is pitched in
  `doc/pitches/components-as-controllers.md`.
- **Reordering of multiple attachments.** `has_many_attached` order follows
  the submitted param order, which invites drag-to-reorder UI, persistence
  semantics, and a11y for reordering — none of it here. Figures render in
  attachment order; that is the whole contract.
