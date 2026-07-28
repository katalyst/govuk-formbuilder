# VoiceOver caption capture (spike)

Throwaway tooling (outside the gemspec) to capture what VoiceOver actually
announces during an interaction, so announcement issues can be characterised
from real utterance sequences instead of by ear.

## Why OCR

VoiceOver's spoken output is only faithfully readable from its **caption
panel**, and the panel is opaque to scripting: its AppleScript object
exposes only `enabled` (no text), the `last phrase` object holds a single
slot that updates at *queue* time (so it skips past transient announcements
like "<file> removed"), and the VoiceOver process publishes nothing to the
Accessibility API. The panel, however, renders each statement **speech-timed**
— held on screen for the duration it's spoken, then replaced — so screen
**OCR** of the panel region, polled at sub-statement intervals, catches every
statement in turn. That is the only method here that captures the transient
announcements; the AppleScript-slot and guidepup approaches were tried and
dropped because both read that lossy single slot.

## Setup

1. Enable VoiceOver AppleScript control: VoiceOver Utility (⌘F5 to start VO,
   then VO+F8) → General → **“Allow VoiceOver to be controlled with
   AppleScript”**.
2. Grant the terminal **Screen Recording** permission (System Settings →
   Privacy & Security → Screen Recording) and restart it — `screencapture`
   needs it.
3. Compile the OCR helper (macOS Vision framework):
   ```
   swiftc script/voiceover/ocr.swift -o /tmp/vo-ocr
   ```

## Calibrate the panel region

The capture crops to the caption panel by screen coordinates (`screencapture
-R x,y,w,h`, in points), which are **display- and position-specific**. Find
yours: capture the full screen and OCR it with coordinates to locate the
caption text, then tighten a crop around just the panel (excluding page
content beside it):

```
screencapture -x /tmp/full.png
/tmp/vo-ocr /tmp/full.png --coords        # find the caption text's box
screencapture -x -R 905,82,560,98 /tmp/panel.png
/tmp/vo-ocr /tmp/panel.png                # adjust R until only the panel shows
```

## Capture

```
VO_SCRATCH=/tmp VO_REGION=905,82,560,98 node script/voiceover/capture-ocr.mjs 15
```

`VO_SCRATCH` holds the compiled `vo-ocr` binary and scratch frames;
`VO_REGION` is your calibrated crop. It polls the panel for the given
seconds, logging each statement (wrapped lines joined) as it changes:

```
region 905,82,560,98, 15s

  0.24s  🗣 Gallery, No file chosen, Choose file or drop file, button group
  2.60s  🗣 bikes 2.jpg removed
```

Drive the interaction by hand with **real keys** (VoiceOver only announces
for real key events — VO+Space to activate), then keep off the keyboard
until the window ends so the panel isn't overwritten by other narration.

Protocol learnings from the F7 runs:

- **Suspect network timing before input method.** A missing outcome
  announcement means the live-region write landed inside the selection's
  announcement traffic — verified both ways: throttled runs voice success
  and failure regardless of input method, unthrottled runs lose them.
  Mouse steps do change the *focus* narration (no dialog-close or focus
  re-read when focus stays in Finder), so keep input consistent across
  runs being compared.
- **Statements are held ~3.4s each**, so queued announcements drain slowly:
  size the window generously (30s+) or trailing statements are clipped.
- **Devtools network throttling is the timing probe.** Local uploads finish
  inside the selection's own announcement traffic (count re-read,
  dialog-close, focus re-read), which is exactly where live-region writes
  get dropped; throttling moves the upload-outcome write clear of the
  traffic so the two effects can be told apart.
