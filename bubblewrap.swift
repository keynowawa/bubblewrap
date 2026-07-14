import AppKit

class BubbleWrapView: NSView {
    var hasPoppedInCurrentPress = false
    
    override var acceptsFirstResponder: Bool { return true }
    
    override func pressureChange(with event: NSEvent) {
        let pressure = event.pressure // 0.0 to 1.0 (stage 1)
        let stage = event.stage       // 1 for normal click, 2 for Force Click
        
        // When we hit a Force Click (stage 2) and haven't popped yet for this press
        if stage == 2 && !hasPoppedInCurrentPress {
            // 1. Trigger Haptic Feedback (vibration)
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
            
            // 2. Play System Pop Sound
            NSSound(named: "Pop")?.play()
            
            print("POP! 💥")
            hasPoppedInCurrentPress = true
            
            // 3. Visual feedback: Flash window color
            self.layer?.backgroundColor = NSColor.systemTeal.cgColor
            
        } else if stage != 2 {
            // Reset state the moment you release the 'Force Click', 
            // even if your finger is still resting on the trackpad.
            hasPoppedInCurrentPress = false
            self.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        }
    }
}

// Setup a minimal Application without Xcode
let app = NSApplication.shared
app.setActivationPolicy(.regular) // Makes it appear in the dock

let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 450, height: 300),
    styleMask: [.titled, .closable, .miniaturizable],
    backing: .buffered,
    defer: false
)
window.center()
window.title = "Trackpad Bubble Wrap"

let view = BubbleWrapView(frame: window.contentRect(forFrameRect: window.frame))
view.wantsLayer = true
view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
window.contentView = view

// Add instructions text to the window
let label = NSTextField(labelWithString: "Press down HARD anywhere on the trackpad\n(Force Click) to POP a bubble!")
label.alignment = .center
label.font = NSFont.systemFont(ofSize: 18, weight: .semibold)
label.frame = NSRect(x: 0, y: 120, width: 450, height: 50)
label.autoresizingMask = [.width, .minYMargin, .maxYMargin]
view.addSubview(label)

window.makeKeyAndOrderFront(nil)
app.activate(ignoringOtherApps: true)

print("Bubble Wrap App is running!")
print("Make sure the window is focused, and PRESS HARD on your trackpad.")
print("(Press Ctrl+C in the terminal or close the window to quit)")

app.run()
