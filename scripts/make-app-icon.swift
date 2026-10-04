import AppKit
import CoreGraphics
import ImageIO

guard CommandLine.arguments.count == 3 else {
    fatalError("Usage: make-app-icon.swift source.png output.iconset")
}

let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1])
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
let fileManager = FileManager.default
try? fileManager.removeItem(at: outputURL)
try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true)

guard let source = NSImage(contentsOf: sourceURL),
      let sourceCG = source.cgImage(forProposedRect: nil, context: nil, hints: nil),
      let crop = sourceCG.cropping(to: CGRect(x: 202, y: 201, width: 850, height: 850)) else {
    fatalError("Could not load or crop the supplied icon image")
}

func render(size: Int) -> CGImage {
    let dimension = CGFloat(size)
    guard let context = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { fatalError("Could not create icon bitmap") }

    let scale = dimension / 850
    context.scaleBy(x: scale, y: scale)
    context.addPath(CGPath(roundedRect: CGRect(x: 0, y: 0, width: 850, height: 850), cornerWidth: 205, cornerHeight: 205, transform: nil))
    context.clip()
    context.draw(crop, in: CGRect(x: 0, y: 0, width: 850, height: 850))
    guard let image = context.makeImage() else { fatalError("Could not render icon") }
    return image
}

func save(_ image: CGImage, to url: URL) {
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
        fatalError("Could not create PNG at \(url.path)")
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { fatalError("Could not write PNG at \(url.path)") }
}

for (base, pixels) in [(16, 16), (16, 32), (32, 32), (32, 64), (128, 128), (128, 256), (256, 256), (256, 512), (512, 512), (512, 1024)] {
    let suffix = pixels == base ? "" : "@2x"
    let imageName = "icon_\(base)x\(base)\(suffix).png"
    save(render(size: pixels), to: outputURL.appendingPathComponent(imageName))
}
