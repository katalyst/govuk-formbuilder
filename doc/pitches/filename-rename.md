# Pitch: attachment filename rename (copy-on-write)

Let a user rename an attachment from the field — fixing upload-time noise
(camera names, percent-encoded filenames) without re-uploading the file.
Not scheduled; the groundwork below is verified against activestorage
8.1.3.

## Verified groundwork

- `filename` is pure blob metadata — the stored object lives at `blob.key`
  (random secure token), so a rename never moves bytes and never
  invalidates `signed_id` (encodes the blob id only) or variants (keyed by
  `key`). Download names resolve at request time on the Disk and
  private-S3 paths; **public-mode services bake Content-Disposition into
  the object at upload**, so a plain rename leaves stale download names
  there.
- No client-writable rename surface exists: ActiveStorage's only writable
  routes are `POST /direct_uploads` (create) and the Disk byte `PUT`. Any
  JS rename needs an endpoint of ours or the consumer's.
- In-place `blob.update(filename:)` was set aside as an option shape: it
  mutates persisted (possibly shared — filename is per-blob, not
  per-attachment) data outside the form's submit-time-truth model, on the
  strength of a signed id that is not a secret in practice (every rendered
  select carries one).

## Proposed shape: copy-on-write

`Blob.compose([blob], filename:)` with a single source is
copy-with-rename — new record, new key, new signed id, bytes copied by the
service (Disk file copy; S3 streams through the app, not a server-side
COPY). `blob.open` + `Blob.create_and_upload!` is the alternative that
re-runs checksum and Marcel identification (compose copies the source
`content_type`, so extension edits want `create_and_upload!`). Never point
a second blob record at an existing key: purging either blob deletes the
shared bytes.

A renamed copy is indistinguishable from a swap upload, so the field's
existing contract absorbs it: JS writes the new signed id into the keep
option (the same write direct-upload success does), submit is swap
semantics with the old attachment's `purge_later` cleaning the old bytes,
an abandoned form leaves only a persisted-unattached orphan (the GC
category direct upload already creates), and an invalid submit round-trips
the new name. The endpoint is creation-only — worst case is orphan copies,
the same risk class as direct-upload spam — though it still wants
rate/authz consideration.

## Costs

A full byte copy per rename (double storage until GC, transits the app
server); variants regenerate lazily for the new key; each re-edit mints
another orphan.

## The client-side freebie

Fresh (client-held) uploads need none of this: the name rides the
direct-upload blob-creation request, so rename-before-upload is
client-side only. The same hook could normalise percent-encoded filenames
at creation — the case the field's VoiceOver review flagged as encoding
noise.

## Open if pursued

The edit affordance in the figure (caption, keep option, remove/retry
labels all regenerate), and which states offer rename (likely
`upload-successful` and server-rendered figures only).
