import AppKit

class Bubble {
    var isPopped = false
    var layer: CAShapeLayer
    init(layer: CAShapeLayer) {
        self.layer = layer
    }
}

class BubbleWrapView: NSView {
    let columns = 12
    let rows = 8
    var bubbles: [[Bubble]] = []
    
    var currentTouchPosition: NSPoint = .zero
    var currentStage = 0
    
    // A red dot to show where the finger physically is on the trackpad
    let fingerIndicator = CAShapeLayer()
    
    override var acceptsFirstResponder: Bool { return true }
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        self.acceptsTouchEvents = true
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        // Setup finger indicator
        let indicatorSize: CGFloat = 20
        fingerIndicator.frame = NSRect(x: -100, y: -100, width: indicatorSize, height: indicatorSize)
        fingerIndicator.path = CGPath(ellipseIn: NSRect(x: 0, y: 0, width: indicatorSize, height: indicatorSize), transform: nil)
        fingerIndicator.fillColor = NSColor.red.cgColor
        fingerIndicator.zPosition = 100 // Keep it on top
        self.layer?.addSublayer(fingerIndicator)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func setupBubbles() {
        let bubbleWidth = self.bounds.width / CGFloat(columns)
        let bubbleHeight = self.bounds.height / CGFloat(rows)
        
        for y in 0..<rows {
            var rowBubbles: [Bubble] = []
            for x in 0..<columns {
                let circleLayer = CAShapeLayer()
                let padding: CGFloat = 4
                let circleRect = NSRect(x: CGFloat(x) * bubbleWidth + padding, 
                                        y: CGFloat(y) * bubbleHeight + padding, 
                                        width: bubbleWidth - padding*2, 
                                        height: bubbleHeight - padding*2)
                circleLayer.path = CGPath(ellipseIn: circleRect, transform: nil)
                circleLayer.fillColor = NSColor.systemTeal.withAlphaComponent(0.8).cgColor
                circleLayer.strokeColor = NSColor.white.cgColor
                circleLayer.lineWidth = 2
                
                self.layer?.addSublayer(circleLayer)
                let bubble = Bubble(layer: circleLayer)
                rowBubbles.append(bubble)
            }
            bubbles.append(rowBubbles)
        }
    }
    
    override func touchesBegan(with event: NSEvent) { updateTouch(event: event) }
    override func touchesMoved(with event: NSEvent) { updateTouch(event: event) }
    override func touchesEnded(with event: NSEvent) { fingerIndicator.isHidden = true }
    override func touchesCancelled(with event: NSEvent) { fingerIndicator.isHidden = true }
    
    func updateTouch(event: NSEvent) {
        if let touch = event.touches(matching: .touching, in: self).first {
            currentTouchPosition = touch.normalizedPosition
            fingerIndicator.isHidden = false
            
            // Map normalized position (0..1) to view bounds
            let viewX = currentTouchPosition.x * self.bounds.width
            let viewY = currentTouchPosition.y * self.bounds.height
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            fingerIndicator.position = CGPoint(x: viewX - 10, y: viewY - 10)
            CATransaction.commit()
            
            // Allow "drag popping" if they slide their finger while pressing hard
            if currentStage == 2 {
                tryPopBubble()
            }
        }
    }
    
    override func pressureChange(with event: NSEvent) {
        currentStage = event.stage       
        if currentStage == 2 {
            tryPopBubble()
        }
    }
    
    func tryPopBubble() {
        let xIndex = Int(currentTouchPosition.x * CGFloat(columns))
        let yIndex = Int(currentTouchPosition.y * CGFloat(rows))
        
        if xIndex >= 0 && xIndex < columns && yIndex >= 0 && yIndex < rows {
            let bubble = bubbles[yIndex][xIndex]
            if !bubble.isPopped {
                bubble.isPopped = true
                
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                bubble.layer.fillColor = NSColor.clear.cgColor
                bubble.layer.strokeColor = NSColor.systemGray.withAlphaComponent(0.3).cgColor
                CATransaction.commit()
                
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                NSSound(named: "Pop")?.play()
            }
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)

let screenRect = NSScreen.main!.visibleFrame
let window = NSWindow(
    contentRect: screenRect,
    styleMask: [.titled, .closable, .miniaturizable, .resizable],
    backing: .buffered,
    defer: false
)
window.center()
window.title = "Absolute Grid Bubble Wrap"

let view = BubbleWrapView(frame: window.contentRect(forFrameRect: window.frame))
window.contentView = view

window.makeKeyAndOrderFront(nil)
app.activate(ignoringOtherApps: true)

// Must setup bubbles after view is laid out
view.setupBubbles()

// Add instructions label on top
let label = NSTextField(labelWithString: "The red dot tracks your finger's absolute position on the physical trackpad.\nPress hard to pop the bubble underneath it!")
label.alignment = .center
label.font = NSFont.systemFont(ofSize: 22, weight: .bold)
label.textColor = NSColor.white
label.backgroundColor = NSColor.black.withAlphaComponent(0.6)
label.drawsBackground = true
label.frame = NSRect(x: 0, y: window.contentRect(forFrameRect: window.frame).height / 2 - 40, width: screenRect.width, height: 80)
view.addSubview(label)

// Fade out instructions after a few seconds
DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
    NSAnimationContext.runAnimationGroup({ context in
        context.duration = 1.0
        label.animator().alphaValue = 0
    })
}

print("Grid Bubble Wrap is running!")
app.run()
