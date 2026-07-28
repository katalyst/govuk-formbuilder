// Vision-framework OCR: prints the text recognised in an image, ordered
// top-to-bottom, one observation per line. Used to read VoiceOver's caption
// panel (which is opaque to AppleScript and the Accessibility API) from a
// screenshot of its region.
//
//   swift script/voiceover/ocr.swift <image.png>
import Foundation
import Vision
import AppKit

guard CommandLine.arguments.count > 1,
      let image = NSImage(contentsOfFile: CommandLine.arguments[1]),
      let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
else {
    FileHandle.standardError.write(Data("usage: ocr.swift <image.png>\n".utf8))
    exit(1)
}

let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.usesLanguageCorrection = false

let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
try? handler.perform([request])

let observations = (request.results ?? [])
    // Vision's origin is bottom-left; sort descending y for reading order.
    .sorted { $0.boundingBox.origin.y > $1.boundingBox.origin.y }

// With --coords, prefix each line with its pixel bounding box (for locating
// a region on a full-screen capture); otherwise print text only.
let showCoords = CommandLine.arguments.contains("--coords")
let w = CGFloat(cgImage.width)
let h = CGFloat(cgImage.height)

for observation in observations {
    guard let text = observation.topCandidates(1).first?.string else { continue }
    if showCoords {
        let b = observation.boundingBox
        let px = Int(b.origin.x * w)
        let py = Int((1 - b.origin.y - b.height) * h) // top-left origin, pixels
        print("[x=\(px) y=\(py) w=\(Int(b.width * w)) h=\(Int(b.height * h))] \(text)")
    } else {
        print(text)
    }
}
