import AppKit

enum BubbleType {
    case regular
    case stubborn(health: Int)
    case double
}

class Bubble {
    var type: BubbleType
    var isPopped = false
    var layer: CAShapeLayer
    
    init(type: BubbleType, layer: CAShapeLayer) {
        self.type = type
        self.layer = layer
    }
}

class BubbleWrapView: NSView {
    let columns = 10
    let rows = 6
    var bubbles: [[Bubble]] = []
    
    var currentTouchPosition: NSPoint = .zero
    var currentStage = 0
    var trackingArea: NSTrackingArea?
    
    let fingerIndicator = CAShapeLayer()
    
    // Store playing sounds to prevent them from being deallocated instantly
    var activeSounds: [NSSound] = []
    
    override var acceptsFirstResponder: Bool { return true }
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        self.acceptsTouchEvents = true
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor(white: 0.1, alpha: 1.0).cgColor // Dark mode
        
        let indicatorSize: CGFloat = 16
        fingerIndicator.frame = NSRect(x: -100, y: -100, width: indicatorSize, height: indicatorSize)
        fingerIndicator.path = CGPath(ellipseIn: NSRect(x: 0, y: 0, width: indicatorSize, height: indicatorSize), transform: nil)
        fingerIndicator.fillColor = NSColor.white.withAlphaComponent(0.5).cgColor
        fingerIndicator.zPosition = 100
        self.layer?.addSublayer(fingerIndicator)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let area = trackingArea { self.removeTrackingArea(area) }
        // Add tracking area to hide mouse cursor when it's inside the window
        let area = NSTrackingArea(rect: self.bounds, options: [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect], owner: self, userInfo: nil)
        self.addTrackingArea(area)
        trackingArea = area
    }
    
    override func mouseEntered(with event: NSEvent) { NSCursor.hide() }
    override func mouseExited(with event: NSEvent) { NSCursor.unhide() }
    
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
                
                // Randomize type for variety
                let rand = Int.random(in: 0..<100)
                let type: BubbleType
                if rand < 15 {
                    type = .stubborn(health: 3)
                    circleLayer.fillColor = NSColor.systemRed.withAlphaComponent(0.8).cgColor
                } else if rand < 30 {
                    type = .double
                    circleLayer.fillColor = NSColor.systemPurple.withAlphaComponent(0.8).cgColor
                } else {
                    type = .regular
                    circleLayer.fillColor = NSColor.systemTeal.withAlphaComponent(0.6).cgColor
                }
                
                circleLayer.strokeColor = NSColor.white.withAlphaComponent(0.2).cgColor
                circleLayer.lineWidth = 1
                
                self.layer?.addSublayer(circleLayer)
                rowBubbles.append(Bubble(type: type, layer: circleLayer))
            }
            bubbles.append(rowBubbles)
        }
    }
    
    func playSound(_ name: String) {
        // Load fresh instance to allow overlapping sounds
        if let url = URL(fileURLWithPath: "/System/Library/Sounds/\(name).aiff") as URL? {
            if let sound = NSSound(contentsOf: url, byReference: true) {
                activeSounds.append(sound)
                sound.play()
                // Clean up finished sounds periodically
                activeSounds.removeAll { !$0.isPlaying }
            }
        }
    }
    
    func triggerHaptic(_ pattern: NSHapticFeedbackManager.FeedbackPattern = .generic) {
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .now)
    }
    
    override func touchesBegan(with event: NSEvent) { updateTouch(event: event) }
    override func touchesMoved(with event: NSEvent) { updateTouch(event: event) }
    override func touchesEnded(with event: NSEvent) { fingerIndicator.isHidden = true }
    override func touchesCancelled(with event: NSEvent) { fingerIndicator.isHidden = true }
    
    func updateTouch(event: NSEvent) {
        if let touch = event.touches(matching: .touching, in: self).first {
            currentTouchPosition = touch.normalizedPosition
            fingerIndicator.isHidden = false
            
            let viewX = currentTouchPosition.x * self.bounds.width
            let viewY = currentTouchPosition.y * self.bounds.height
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            fingerIndicator.position = CGPoint(x: viewX - 8, y: viewY - 8)
            CATransaction.commit()
            
            if currentStage == 2 { tryPopBubble() }
        }
    }
    
    override func pressureChange(with event: NSEvent) {
        // Only register a new press if we actually transitioned to stage 2
        let previousStage = currentStage
        currentStage = event.stage       
        if currentStage == 2 && previousStage < 2 {
            tryPopBubble()
        } else if currentStage == 2 {
            // Also allow drag-popping
            tryPopBubble()
        }
    }
    
    func tryPopBubble() {
        let xIndex = Int(currentTouchPosition.x * CGFloat(columns))
        let yIndex = Int(currentTouchPosition.y * CGFloat(rows))
        
        if xIndex >= 0 && xIndex < columns && yIndex >= 0 && yIndex < rows {
            let bubble = bubbles[yIndex][xIndex]
            if !bubble.isPopped {
                processPop(bubble: bubble)
            }
        }
    }
    
    var isProcessingPop = false // Prevent rapid re-triggering on stubborn bubbles during drag
    
    func processPop(bubble: Bubble) {
        if isProcessingPop { return }
        
        switch bubble.type {
        case .regular:
            bubble.isPopped = true
            setPoppedVisuals(bubble.layer)
            playSound("Pop")
            triggerHaptic(.levelChange)
            
        case .double:
            bubble.isPopped = true
            setPoppedVisuals(bubble.layer)
            
            // First pop
            playSound("Tink")
            triggerHaptic(.levelChange)
            
            // Second pop slightly delayed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.playSound("Pop")
                self.triggerHaptic(.alignment)
            }
            
        case .stubborn(let health):
            isProcessingPop = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { self.isProcessingPop = false }
            
            if health <= 1 {
                // Finally pops
                bubble.type = .stubborn(health: 0)
                bubble.isPopped = true
                setPoppedVisuals(bubble.layer)
                playSound("Glass") // satisfying shatter
                triggerHaptic(.levelChange)
            } else {
                // Takes damage but doesn't pop
                bubble.type = .stubborn(health: health - 1)
                playSound("Basso") // Thud sound
                triggerHaptic(.generic)
                
                // Visual feedback for hitting it
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                if health == 3 {
                    bubble.layer.fillColor = NSColor.systemOrange.withAlphaComponent(0.8).cgColor
                } else if health == 2 {
                    bubble.layer.fillColor = NSColor.systemYellow.withAlphaComponent(0.8).cgColor
                }
                bubble.layer.transform = CATransform3DMakeScale(0.85, 0.85, 1.0)
                CATransaction.commit()
                
                // Reset scale shortly after
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    bubble.layer.transform = CATransform3DIdentity
                    CATransaction.commit()
                }
            }
        }
    }
    
    func setPoppedVisuals(_ layer: CAShapeLayer) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.fillColor = NSColor.clear.cgColor
        layer.strokeColor = NSColor.white.withAlphaComponent(0.1).cgColor
        layer.transform = CATransform3DIdentity
        CATransaction.commit()
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)

// Make window 16:10 aspect ratio to perfectly mimic trackpad
let trackpadRatio: CGFloat = 16.0 / 10.0
let width: CGFloat = 450
let height = width / trackpadRatio

let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: width, height: height),
    styleMask: [.titled, .closable, .miniaturizable],
    backing: .buffered,
    defer: false
)
window.center()
window.title = "Pocket Bubble Wrap"
window.backgroundColor = NSColor(white: 0.1, alpha: 1.0)

let view = BubbleWrapView(frame: window.contentRect(forFrameRect: window.frame))
window.contentView = view

window.makeKeyAndOrderFront(nil)
app.activate(ignoringOtherApps: true)

view.setupBubbles()

print("Pocket Bubble Wrap running!")
app.run()
