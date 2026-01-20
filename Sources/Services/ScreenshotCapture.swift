import AppKit
import CoreGraphics

class ScreenshotCapture: ScreenshotCapturing {

    func captureScreen() throws -> NSImage {
        guard let mainScreen = NSScreen.main else {
            throw ScreenshotError.screenNotFound
        }

        let frame = mainScreen.frame
        let rect = CGRect(origin: .zero, size: frame.size)

        // TODO: ScreenCaptureKitへの移行 (v1.1で計画中)
        guard let cgImage = CGWindowListCreateImage(rect, .optionOnScreenOnly, kCGNullWindowID, .bestResolution) else {
            throw ScreenshotError.captureFailed
        }

        return NSImage(cgImage: cgImage, size: frame.size)
    }

    func captureScreenAndSave(to url: URL) throws {
        let image = try captureScreen()

        guard let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData)
        else {
            throw ScreenshotError.imageProcessingFailed
        }

        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw ScreenshotError.imageProcessingFailed
        }

        try pngData.write(to: url)
    }

    func captureScreenAsData() throws -> Data {
        let image = try captureScreen()

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

    func captureRect(_ rect: CGRect, from screen: NSScreen) throws -> NSImage {
        let frame = screen.frame
        let screenRect = CGRect(
            x: rect.origin.x,
            y: frame.height - rect.maxY,
            width: rect.width,
            height: rect.height
        )

        // TODO: ScreenCaptureKitへの移行 (v1.1で計画中)
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

enum ScreenshotError: LocalizedError {
    case screenNotFound
    case captureFailed
    case imageConversionFailed
    case imageProcessingFailed

    var errorDescription: String? {
        switch self {
        case .screenNotFound:
            return "メインスクリーンが見つかりません"
        case .captureFailed:
            return "スクリーンショットの取得に失敗しました"
        case .imageConversionFailed:
            return "画像の変換に失敗しました"
        case .imageProcessingFailed:
            return "画像の処理に失敗しました"
        }
    }
}
