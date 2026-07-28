#!/usr/bin/env node
// Reads VoiceOver's caption panel by OCR — the only faithful source, since
// the panel is opaque to AppleScript/AX. The panel renders each statement
// speech-timed (held for the duration it's spoken, then replaced), so
// polling the region at sub-statement intervals catches every statement in
// turn, including the transient "removed" the AppleScript `last phrase`
// slot drops.
//
// Calibrate REGION (screencapture -R points: x,y,w,h) to your caption panel
// with the calibration captures in the README. Run this, perform a removal
// (real VO+Space so VoiceOver actually announces), then Ctrl-C or wait out
// the window.
//
//   node script/voiceover/capture-ocr.mjs [seconds]
import { execFileSync } from "node:child_process";
import { writeFileSync } from "node:fs";

const SCRATCH = process.env.VO_SCRATCH ?? ".";
const OCR = process.env.VO_OCR ?? `${SCRATCH}/vo-ocr`; // swiftc ocr.swift -o $SCRATCH/vo-ocr
const REGION = process.env.VO_REGION ?? "905,82,560,98";
const FRAME = `${SCRATCH}/vo-frame.png`;
const WINDOW_S = Number(process.argv[2] ?? 20);

const norm = (s) => s.replace(/\s+/g, " ").trim();

// The panel's current statement = its wrapped lines joined. Ignore the
// leading "X"/"x" close-button glyph the OCR sometimes prepends.
function readPanel() {
  execFileSync("screencapture", ["-x", "-R", REGION, FRAME]);
  const lines = execFileSync(OCR, [FRAME], { encoding: "utf8" })
    .split("\n")
    .map(norm)
    .filter(Boolean);
  return norm(lines.join(" ").replace(/^[Xx]\s+/, ""));
}

const t0 = Date.now();
const seq = [];
let last = null;

while (Date.now() - t0 < WINDOW_S * 1000) {
  let statement = "";
  try {
    statement = readPanel();
  } catch {
    // transient capture/OCR failure; keep polling
  }
  if (statement && statement !== last) {
    seq.push({ at: Date.now() - t0, statement });
    last = statement;
  }
}

console.log(`region ${REGION}, ${WINDOW_S}s\n`);
for (const { at, statement } of seq) {
  console.log(`${(at / 1000).toFixed(2).padStart(6)}s  🗣 ${statement}`);
}
writeFileSync(`${SCRATCH}/vo-ocr-transcript.txt`, seq.map((s) => `${(s.at / 1000).toFixed(2)}\t${s.statement}`).join("\n"));
