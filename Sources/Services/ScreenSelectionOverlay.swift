import AppKit
import QuartzCore

protocol ScreenSelectionDelegate: AnyObject {
    func didSelectRect(_ rect: CGRect)
    func didCancelSelection()
}

class ScreenSelectionOverlay: NSPanel {
    weak var selectionDelegate: ScreenSelectionDelegate?
    private var startPoint: NSPoint?
    private var currentRect: NSRect = .zero
    private var overlayLayer: CAShapeLayer?
    private var selectionLayer: CAShapeLayer?
    private let selectionColor: NSColor = NSColor.orange.withAlphaComponent(0.5)
    private let borderColor: NSColor = .white

    override init(
        contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool
    ) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        setupWindow()
    }

    convenience init(screen: NSScreen) {
        let contentRect = screen.frame
        self.init(contentRect: contentRect, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        self.level = .screenSaver
        self.backgroundColor = NSColor.black.withAlphaComponent(0.3)
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        self.hidesOnDeactivate = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }

    private func setupWindow() {
        let contentView = NSView(frame: self.frame)
        self.contentView = contentView

        self.contentView?.wantsLayer = true

        overlayLayer = CAShapeLayer()
        overlayLayer?.fillColor = NSColor.black.withAlphaComponent(0.3).cgColor
        overlayLayer?.frame = self.frame
        self.contentView?.layer?.addSublayer(overlayLayer!)

        selectionLayer = CAShapeLayer()
        selectionLayer?.fillColor = selectionColor.cgColor
        selectionLayer?.strokeColor = borderColor.cgColor
        selectionLayer?.lineWidth = 2.0
        self.contentView?.layer?.addSublayer(selectionLayer!)
    }

    func showOverlay(on screen: NSScreen) {
        let contentRect = screen.frame
        self.setFrame(contentRect, display: true)
        self.orderFrontRegardless()
        self.makeKey()
    }

    func hideOverlay() {
        self.orderOut(nil)
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = event.locationInWindow
        currentRect = CGRect(origin: startPoint!, size: .zero)
        updateSelection()
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = startPoint else { return }
        let current = event.locationInWindow

        let x = min(start.x, current.x)
        let y = min(start.y, current.y)
        let width = abs(current.x - start.x)
        let height = abs(current.y - start.y)

        currentRect = CGRect(x: x, y: y, width: width, height: height)
        updateSelection()
    }

    override func mouseUp(with event: NSEvent) {
        guard startPoint != nil else {
            cancelSelection()
            return
        }

        let minSelectionSize: CGFloat = 50.0

        if currentRect.width < minSelectionSize || currentRect.height < minSelectionSize {
            cancelSelection()
        } else {
            selectionDelegate?.didSelectRect(currentRect)
        }

        startPoint = nil
        currentRect = .zero
        updateSelection()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            cancelSelection()
        }
    }

    private func updateSelection() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        selectionLayer?.path = CGPath(rect: currentRect, transform: nil)

        CATransaction.commit()
    }

    private func cancelSelection() {
        currentRect = .zero
        updateSelection()
        selectionDelegate?.didCancelSelection()
    }
}
