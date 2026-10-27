#!/usr/bin/env swift
// Draws the stahpwatch app icon: a white stopwatch outline with an orange hand on black.
// Run from the repo root:  swift Scripts/make_icon.swift
// Shapes are drawn directly (no SF Symbols, which Apple's license excludes from app icons).
import AppKit
import CoreGraphics

let size = 1024
let out = "stahpwatch/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
let gray = CGColor(red: 1, green: 1, blue: 1, alpha: 0.45)
let orange = CGColor(red: 1, green: 0x8B / 255.0, blue: 0, alpha: 1)
let black = CGColor(red: 0, green: 0, blue: 0, alpha: 1)

let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
// Flip to a top-left origin so the numbers below read like screen coordinates.
ctx.translateBy(x: 0, y: CGFloat(size))
ctx.scaleBy(x: 1, y: -1)

ctx.setFillColor(black)
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

let center = CGPoint(x: 512, y: 560)
let radius: CGFloat = 330
let ring: CGFloat = 44

// Crown stem and button on top.
ctx.setFillColor(white)
ctx.fill(CGRect(x: 512 - 34, y: center.y - radius - 70, width: 68, height: 80))
let crown = CGRect(x: 512 - 92, y: center.y - radius - 128, width: 184, height: 66)
ctx.addPath(CGPath(roundedRect: crown, cornerWidth: 26, cornerHeight: 26, transform: nil))
ctx.fillPath()

// Side button at about 1–2 o'clock.
ctx.saveGState()
ctx.translateBy(x: center.x, y: center.y)
ctx.rotate(by: .pi / 4)
ctx.addPath(CGPath(roundedRect: CGRect(x: -30, y: -radius - 72, width: 60, height: 70),
                   cornerWidth: 14, cornerHeight: 14, transform: nil))
ctx.fillPath()
ctx.restoreGState()

// Case outline.
ctx.setStrokeColor(white)
ctx.setLineWidth(ring)
ctx.strokeEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))

// Ticks: 60 minor, 12 major.
ctx.setLineCap(.butt)
for i in 0..<60 {
    let major = i % 5 == 0
    let angle = CGFloat(i) / 60 * 2 * .pi
    let outer = radius - ring / 2 - 26
    let inner = outer - (major ? 62 : 30)
    ctx.setStrokeColor(major ? white : gray)
    ctx.setLineWidth(major ? 16 : 7)
    ctx.move(to: CGPoint(x: center.x + sin(angle) * inner, y: center.y - cos(angle) * inner))
    ctx.addLine(to: CGPoint(x: center.x + sin(angle) * outer, y: center.y - cos(angle) * outer))
    ctx.strokePath()
}

// Orange hand pointing to about 10 seconds, with a tail and hollow center ring.
let handAngle: CGFloat = 2 * .pi * 10 / 60
let tip = radius - ring / 2 - 30
let tail: CGFloat = 70
ctx.setStrokeColor(orange)
ctx.setLineWidth(18)
ctx.setLineCap(.round)
ctx.move(to: CGPoint(x: center.x - sin(handAngle) * tail, y: center.y + cos(handAngle) * tail))
ctx.addLine(to: CGPoint(x: center.x + sin(handAngle) * tip, y: center.y - cos(handAngle) * tip))
ctx.strokePath()
ctx.setFillColor(black)
ctx.fillEllipse(in: CGRect(x: center.x - 26, y: center.y - 26, width: 52, height: 52))
ctx.setLineWidth(14)
ctx.strokeEllipse(in: CGRect(x: center.x - 26, y: center.y - 26, width: 52, height: 52))

let image = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: image)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("Wrote \(out)")
