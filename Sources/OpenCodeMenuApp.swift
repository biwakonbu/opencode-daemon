import Cocoa
import OpenCodeMenuAppCore

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let delegate = AppDelegate()
app.delegate = delegate

app.finishLaunching()
app.run()
