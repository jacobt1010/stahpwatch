#!/usr/bin/env swift
// Converts a screen recording to an animated GIF for the README, with no third-party tools.
// Usage: swift Scripts/make_gif.swift <input.mov> <output.gif> [width=320] [fps=12] [start=0] [end=duration]
// start and end trim the clip, in seconds.
import AVFoundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
guard args.count >= 3 else {
    print("usage: make_gif.swift <input.mov> <output.gif> [width] [fps] [start] [end]")
    exit(1)
}
let input = URL(fileURLWithPath: args[1])
let output = URL(fileURLWithPath: args[2])
let width = args.count > 3 ? Double(args[3])! : 320
let fps = args.count > 4 ? Double(args[4])! : 12
let start = args.count > 5 ? Double(args[5])! : 0

let asset = AVURLAsset(url: input)
let end = args.count > 6 ? Double(args[6])! : CMTimeGetSeconds(asset.duration)
let duration = end - start
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero
generator.maximumSize = CGSize(width: width, height: width * 10)

let frameCount = Int(duration * fps)
guard let dest = CGImageDestinationCreateWithURL(output as CFURL, UTType.gif.identifier as CFString, frameCount, nil) else {
    fatalError("can't create \(output.path)")
}
CGImageDestinationSetProperties(dest, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
let frameProps = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 1 / fps]] as CFDictionary

for i in 0..<frameCount {
    let time = CMTime(seconds: start + Double(i) / fps, preferredTimescale: 600)
    let image = try generator.copyCGImage(at: time, actualTime: nil)
    CGImageDestinationAddImage(dest, image, frameProps)
}
guard CGImageDestinationFinalize(dest) else { fatalError("couldn't write GIF") }
print("Wrote \(output.path): \(frameCount) frames, \(String(format: "%.1f", duration)) s")
