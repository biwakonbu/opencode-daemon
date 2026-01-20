import AppKit
import CoreGraphics
import os.log

class ScreenshotRectCapture {
    private let logger = OSLog(subsystem: "com.opencodemenu.app", category: "ScreenshotRectCapture")

    func captureRect(_ rect: CGRect, from screen: NSScreen) throws -> NSImage {
        let frame = screen.frame
        let screenRect = CGRect(
            x: rect.origin.x,
            y: frame.height - rect.maxY,
            width: rect.width,
            height: rect.height
        )

        guard let cgImage = CGWindowListCreateImage(screenRect, .optionOnScreenOnly, kCGNullWindowID, .bestResolution) else {
            throw ScreenshotError.captureFailed
        }

        return NSImage(cgImage: cgImage, size: rect.size)
    }

    func captureRectAsData(_ rect: CGRect, from screen: NSScreen) throws -> Data {
        let image = try captureRect(rect, from: screen)

        guard let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData)
        else {
            throw ScreenshotError.imageProcessingFailed
        }

        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw ScreenshotError.imageProcessingFailed
        }

        return pngData
    }
}
