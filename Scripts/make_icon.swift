#!/usr/bin/env swift
// Draws the stahpwatch app icon: a simplified Paper dial, ink on cream with a vermilion hand.
// Run from the repo root:  swift Scripts/make_icon.swift
// Shapes are drawn directly (no SF Symbols, which Apple's license excludes from app icons).
import AppKit
import CoreGraphics

let size = 1024
let out = "stahpwatch/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

func color(_ hex: Int) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}
let cream = color(0xF2EBDD)
let ink = color(0x1F1C18)
let vermilion = color(0xD4431C)

let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
// Flip to a top-left origin so the numbers below read like screen coordinates.
ctx.translateBy(x: 0, y: CGFloat(size))
ctx.scaleBy(x: 1, y: -1)

let center = CGPoint(x: 512, y: 512)

/// A point `radius` from the center; `turn` is in full turns, 0 = 12 o'clock, clockwise.
func point(_ radius: CGFloat, _ turn: CGFloat) -> CGPoint {
    let a = turn * 2 * .pi
    return CGPoint(x: center.x + sin(a) * radius, y: center.y - cos(a) * radius)
}

func disc(_ at: CGPoint, _ radius: CGFloat) {
    ctx.fillEllipse(in: CGRect(x: at.x - radius, y: at.y - radius, width: radius * 2, height: radius * 2))
}

ctx.setFillColor(cream)
ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))

// Case outline.
ctx.setStrokeColor(ink)
ctx.setLineWidth(16)
ctx.strokeEllipse(in: CGRect(x: 512 - 370, y: 512 - 370, width: 740, height: 740))

// Twelve ticks.
ctx.setLineWidth(18)
for i in 0..<12 {
    let turn = CGFloat(i) / 12
    ctx.move(to: point(278, turn))
    ctx.addLine(to: point(340, turn))
    ctx.strokePath()
}

// Vermilion hand at 10 seconds, with a counterweight on its tail.
let hand: CGFloat = 1.0 / 6
let tail = point(96, hand + 0.5)
ctx.setStrokeColor(vermilion)
ctx.setLineWidth(16)
ctx.setLineCap(.round)
ctx.move(to: tail)
ctx.addLine(to: point(300, hand))
ctx.strokePath()
ctx.setFillColor(vermilion)
disc(tail, 30)
disc(center, 20)

let image = ctx.makeImage()!
let rep = NSBitmapImageRep(cgImage: image)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
print("Wrote \(out)")
