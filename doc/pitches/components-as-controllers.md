# Pitch: govuk-frontend components as Stimulus controllers

Replace `data-module` sweeping entirely: the server emits
`data-controller`, each govuk-frontend component wraps in a thin
controller (`connect()` constructs it, config from the captured option bag
or govuk's own data-attribute config), and Stimulus's observer owns
arrival — including runtime attribute writes, which would gain a public
contract `data-module` never had. Registration unifies under
`application.load(govuk)` and composes with the gem-owned Stimulus
application pitch. Not scheduled.

## Why the core is small

A base class plus seven registrations.

## Why the edges are the real cost

- **Identifier collision**: the attachment drop zone already owns the
  `govuk-file-upload` identifier — upstream's FileUpload needs a rename,
  and the exclusivity invariant re-encodes.
- **Morphs get worse without work**: Stimulus never re-connects a
  morph-retained element, so stripped injected UI stays broken unless the
  base class self-heals à la `file_upload_controller`'s morphObserver.
  govuk components have no teardown for `disconnect()` to call — the
  original objection to running upstream JS, unresolved by wrapping.
- **Listener leaks become explicit**: FileUpload's document-level drag
  listeners leak on every re-construction in both designs, but a wrapper
  makes the gap visible, and fixing it means forking components.
- **Convention divergence**: consumer-authored `data-module` markup
  silently stops enhancing — a departure from govuk-frontend's documented
  conventions carried into every upstream bump review.
- `initAll` shrinks but survives (markSupport + marker restore — Stimulus
  knows nothing of the body markers). Parity spec, guide pages,
  enhancement/morph specs, and the drop-zone design section all re-encode.
