import AppKit

/// Small, concrete image representations are safe to transport to Finder's menus
/// and customization palette. The SVG remains the editable source of the mark.
enum FinderIcons {
    static let toolbar = logo(size: 18)
    static let menuLogo = logo(size: 16)

    private static func logo(size: Int) -> NSImage {
        let source = Bundle.main.url(forResource: "GogoTemplate", withExtension: "svg")
            .flatMap { NSImage(contentsOf: $0) }
            ?? NSImage(systemSymbolName: "arrow.up.forward", accessibilityDescription: "gogo")!
        let image = rasterized(source, size: size, template: true)
        image.accessibilityDescription = "gogo"
        return image
    }

    static func launcher(_ launcher: Launcher) -> NSImage {
        guard let url = Applications.url(for: launcher) else {
            return symbol(launcher.method == .executable ? "terminal" : "app")
        }
        return rasterized(NSWorkspace.shared.icon(forFile: url.path), size: 16, template: false)
    }

    static func symbol(_ name: String) -> NSImage {
        let source = NSImage(systemSymbolName: name, accessibilityDescription: nil)!
            .withSymbolConfiguration(.init(pointSize: 14, weight: .regular))!
        return rasterized(source, size: 16, template: true)
    }

    static func rasterized(_ source: NSImage, size: Int, template: Bool) -> NSImage {
        let logicalSize = NSSize(width: size, height: size)
        let image = NSImage(size: logicalSize)
        for scale in [1, 2] {
            guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil,
                pixelsWide: size * scale, pixelsHigh: size * scale,
                bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
                let context = NSGraphicsContext(bitmapImageRep: bitmap) else { continue }
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = context
            context.imageInterpolation = .high
            context.cgContext.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
            let factor = min(logicalSize.width / source.size.width, logicalSize.height / source.size.height)
            let fittedSize = NSSize(width: source.size.width * factor, height: source.size.height * factor)
            let rect = NSRect(x: (logicalSize.width - fittedSize.width) / 2,
                              y: (logicalSize.height - fittedSize.height) / 2,
                              width: fittedSize.width, height: fittedSize.height)
            source.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1)
            NSGraphicsContext.restoreGraphicsState()
            // Set the point size after drawing: setting it before creating the
            // context would apply Retina scaling twice.
            bitmap.size = logicalSize
            image.addRepresentation(bitmap)
        }
        image.isTemplate = template
        return image
    }
}
