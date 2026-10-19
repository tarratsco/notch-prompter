import AppKit

private let canvasSize = 1024
private let imageRect = NSRect(x: 0, y: 0, width: canvasSize, height: canvasSize)

private extension NSColor {
    static let iconCanvas = NSColor(
        calibratedRed: 0.055,
        green: 0.055,
        blue: 0.06,
        alpha: 1
    )
    static let iconRaised = NSColor(
        calibratedRed: 0.09,
        green: 0.09,
        blue: 0.10,
        alpha: 1
    )
    static let iconControl = NSColor(
        calibratedRed: 0.14,
        green: 0.135,
        blue: 0.14,
        alpha: 1
    )
    static let iconWarmText = NSColor(
        calibratedRed: 0.96,
        green: 0.93,
        blue: 0.87,
        alpha: 1
    )
    static let iconSecondary = NSColor(
        calibratedRed: 0.65,
        green: 0.62,
        blue: 0.57,
        alpha: 1
    )
    static let iconLive = NSColor(
        calibratedRed: 0.78,
        green: 0.08,
        blue: 0.06,
        alpha: 1
    )
}

private func fillRoundedRect(
    _ rect: NSRect,
    radius: CGFloat,
    color: NSColor
) {
    color.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}

private func strokeRoundedRect(
    _ rect: NSRect,
    radius: CGFloat,
    color: NSColor,
    width: CGFloat
) {
    color.setStroke()
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    path.lineWidth = width
    path.stroke()
}

private func makePrompterShell() -> NSBezierPath {
    let path = NSBezierPath()
    path.move(to: NSPoint(x: 170, y: 850))
    path.line(to: NSPoint(x: 854, y: 850))
    path.curve(
        to: NSPoint(x: 814, y: 810),
        controlPoint1: NSPoint(x: 832, y: 850),
        controlPoint2: NSPoint(x: 814, y: 832)
    )
    path.line(to: NSPoint(x: 814, y: 264))
    path.curve(
        to: NSPoint(x: 738, y: 188),
        controlPoint1: NSPoint(x: 814, y: 222),
        controlPoint2: NSPoint(x: 780, y: 188)
    )
    path.line(to: NSPoint(x: 286, y: 188))
    path.curve(
        to: NSPoint(x: 210, y: 264),
        controlPoint1: NSPoint(x: 244, y: 188),
        controlPoint2: NSPoint(x: 210, y: 222)
    )
    path.line(to: NSPoint(x: 210, y: 810))
    path.curve(
        to: NSPoint(x: 170, y: 850),
        controlPoint1: NSPoint(x: 210, y: 832),
        controlPoint2: NSPoint(x: 192, y: 850)
    )
    path.close()
    return path
}

guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: canvasSize,
    pixelsHigh: canvasSize,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
) else {
    fatalError("Unable to create icon bitmap")
}

guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    fatalError("Unable to create icon drawing context")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.cgContext.clear(imageRect)
context.cgContext.setAllowsAntialiasing(true)
context.cgContext.setShouldAntialias(true)

let tileRect = NSRect(x: 88, y: 88, width: 848, height: 848)
let tilePath = NSBezierPath(roundedRect: tileRect, xRadius: 190, yRadius: 190)
let tileShadow = NSShadow()
tileShadow.shadowColor = NSColor.black.withAlphaComponent(0.48)
tileShadow.shadowBlurRadius = 34
tileShadow.shadowOffset = NSSize(width: 0, height: -18)
tileShadow.set()
NSColor.iconCanvas.setFill()
tilePath.fill()
NSShadow().set()

strokeRoundedRect(
    tileRect.insetBy(dx: 5, dy: 5),
    radius: 185,
    color: NSColor.white.withAlphaComponent(0.10),
    width: 10
)

let shell = makePrompterShell()
NSColor.black.setFill()
shell.fill()
NSColor.white.withAlphaComponent(0.13).setStroke()
shell.lineWidth = 8
shell.stroke()

fillRoundedRect(
    NSRect(x: 376, y: 774, width: 272, height: 112),
    radius: 48,
    color: .iconRaised
)
fillRoundedRect(
    NSRect(x: 484, y: 812, width: 56, height: 22),
    radius: 11,
    color: .iconControl
)

fillRoundedRect(
    NSRect(x: 300, y: 642, width: 424, height: 34),
    radius: 17,
    color: NSColor.iconSecondary.withAlphaComponent(0.52)
)
fillRoundedRect(
    NSRect(x: 340, y: 544, width: 344, height: 38),
    radius: 19,
    color: .iconWarmText
)
fillRoundedRect(
    NSRect(x: 278, y: 402, width: 468, height: 34),
    radius: 17,
    color: NSColor.iconSecondary.withAlphaComponent(0.52)
)
fillRoundedRect(
    NSRect(x: 346, y: 318, width: 332, height: 34),
    radius: 17,
    color: NSColor.iconSecondary.withAlphaComponent(0.36)
)

NSColor.iconLive.setFill()
NSBezierPath(rect: NSRect(x: 250, y: 558, width: 524, height: 12)).fill()

NSGraphicsContext.restoreGraphicsState()

let outputURL = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "AppIcon-1024.png")
guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Unable to encode icon PNG")
}
try pngData.write(to: outputURL)
