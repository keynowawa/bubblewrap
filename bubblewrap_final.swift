import AppKit

enum BubbleType {
    case regular
    case hold
}

class Bubble {
    var rect: NSRect
    var isPopped = false
    var type: BubbleType
    
    var isHolding = false
    var pinchAmount: CGFloat = 0.0 // 0.0 to 1.0
    
    init(rect: NSRect, type: BubbleType) {
        self.rect = rect
        self.type = type
    }
}

class BubbleWrapView: NSView {
    let columns = 8 
    let rows = 5
    var bubbles: [[Bubble]] = []
    
    var currentTouchPosition: NSPoint = .zero
    var currentStage = 0
    var trackingArea: NSTrackingArea?
    
    let fingerIndicator = CAShapeLayer()
    var activeSounds: [NSSound] = []
    var animationTimer: Timer?
    
    override var acceptsFirstResponder: Bool { return true }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // 53 is the ESC key
            NSApplication.shared.terminate(nil)
        } else {
            super.keyDown(with: event)
        }
    }
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        self.acceptsTouchEvents = true
        self.wantsLayer = true
        
        let indicatorSize: CGFloat = 20
        fingerIndicator.frame = NSRect(x: 0, y: 0, width: indicatorSize, height: indicatorSize)
        fingerIndicator.path = CGPath(ellipseIn: NSRect(x: -indicatorSize/2, y: -indicatorSize/2, width: indicatorSize, height: indicatorSize), transform: nil)
        // Soft white glow for the finger
        fingerIndicator.fillColor = NSColor.white.withAlphaComponent(0.25).cgColor
        fingerIndicator.shadowColor = NSColor.black.cgColor
        fingerIndicator.shadowOpacity = 0.4
        fingerIndicator.shadowRadius = 4
        fingerIndicator.shadowOffset = .zero
        fingerIndicator.zPosition = 100
        fingerIndicator.isHidden = true
        self.layer?.addSublayer(fingerIndicator)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if animationTimer == nil {
            animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
                self?.updateAnimations()
            }
        }
    }
    
    func updateAnimations() {
        var needsRedraw = false
        for row in bubbles {
            for bubble in row {
                if bubble.isHolding && !bubble.isPopped {
                    if bubble.pinchAmount < 1.0 {
                        bubble.pinchAmount += 1.0 / 40.0 // About 0.6 seconds to pinch and pop
                        needsRedraw = true
                        if bubble.pinchAmount >= 1.0 {
                            bubble.isHolding = false
                            processPop(bubble: bubble)
                        }
                    }
                } else if !bubble.isHolding && bubble.pinchAmount > 0.0 && !bubble.isPopped {
                    // Release the pinch quickly
                    bubble.pinchAmount -= 1.0 / 10.0
                    if bubble.pinchAmount < 0.0 { bubble.pinchAmount = 0.0 }
                    needsRedraw = true
                }
            }
        }
        if needsRedraw {
            self.needsDisplay = true
        }
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let area = trackingArea { self.removeTrackingArea(area) }
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
                let rect = NSRect(x: CGFloat(x) * bubbleWidth, 
                                  y: CGFloat(y) * bubbleHeight, 
                                  width: bubbleWidth, 
                                  height: bubbleHeight)
                
                // No colors or visual hints. Some bubbles just require a pinch.
                let isHold = Int.random(in: 0..<100) < 60 // 60% require holding/pinching for more satisfaction
                
                let bubble = Bubble(rect: rect, type: isHold ? .hold : .regular)
                rowBubbles.append(bubble)
            }
            bubbles.append(rowBubbles)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        // Faint plastic sheet over everything to unify the bubbles
        // The rest is totally transparent frosted glass!
        NSColor(white: 1.0, alpha: 0.03).setFill()
        dirtyRect.fill()
        
        for row in bubbles {
            for bubble in row {
                if dirtyRect.intersects(bubble.rect) {
                    drawBubble(bubble)
                }
            }
        }
    }
    
    func drawBubble(_ bubble: Bubble) {
        let padding: CGFloat = 4
        let circleRect = bubble.rect.insetBy(dx: padding, dy: padding)
        
        NSGraphicsContext.saveGraphicsState()
        
        // Physical Pinch Animation
        if bubble.pinchAmount > 0.0 && !bubble.isPopped {
            let center = CGPoint(x: circleRect.midX, y: circleRect.midY)
            let transform = NSAffineTransform()
            transform.translateX(by: center.x, yBy: center.y)
            // Squeeze inwards from the sides, bulge slightly up
            let scaleX = 1.0 - (0.35 * bubble.pinchAmount)
            let scaleY = 1.0 + (0.15 * bubble.pinchAmount)
            transform.scaleX(by: scaleX, yBy: scaleY)
            transform.translateX(by: -center.x, yBy: -center.y)
            transform.concat()
        }
        
        if bubble.isPopped {
            // Wrinkled clear plastic look (flat)
            NSColor(white: 0.9, alpha: 0.05).setFill()
            NSBezierPath(ovalIn: circleRect).fill()
            
            NSColor(white: 1.0, alpha: 0.15).setStroke()
            let path = NSBezierPath(ovalIn: circleRect)
            path.lineWidth = 1.0
            path.stroke()
            
            // Random inner wrinkles
            let crinkle = NSBezierPath()
            crinkle.move(to: NSPoint(x: circleRect.minX + 8, y: circleRect.midY + 3))
            crinkle.line(to: NSPoint(x: circleRect.midX - 3, y: circleRect.midY - 5))
            crinkle.line(to: NSPoint(x: circleRect.maxX - 6, y: circleRect.midY + 4))
            NSColor(white: 1.0, alpha: 0.25).setStroke()
            crinkle.lineWidth = 0.5
            crinkle.stroke()
        } else {
            // Hyper-Realistic 3D Clear Plastic Bubble
            
            // Base milky fill
            NSColor(white: 0.95, alpha: 0.15).setFill()
            NSBezierPath(ovalIn: circleRect).fill()
            
            // Top-left bright reflection
            let lightGradient = NSGradient(starting: NSColor(white: 1.0, alpha: 0.6), ending: NSColor(white: 1.0, alpha: 0.0))
            lightGradient?.draw(in: NSBezierPath(ovalIn: circleRect), relativeCenterPosition: NSPoint(x: -0.3, y: 0.3))
            
            // Bottom-right inner shadow for depth
            let darkGradient = NSGradient(starting: NSColor(white: 0.0, alpha: 0.0), ending: NSColor(white: 0.0, alpha: 0.2))
            darkGradient?.draw(in: NSBezierPath(ovalIn: circleRect), relativeCenterPosition: NSPoint(x: 0.3, y: -0.3))
            
            // Sharp Specular highlight
            let highlightRect = NSRect(x: circleRect.minX + circleRect.width * 0.15,
                                       y: circleRect.maxY - circleRect.height * 0.35,
                                       width: circleRect.width * 0.3,
                                       height: circleRect.height * 0.15)
            let highlightPath = NSBezierPath(ovalIn: highlightRect)
            
            NSGraphicsContext.saveGraphicsState()
            let hTransform = NSAffineTransform()
            hTransform.translateX(by: highlightRect.midX, yBy: highlightRect.midY)
            hTransform.rotate(byDegrees: 25)
            hTransform.translateX(by: -highlightRect.midX, yBy: -highlightRect.midY)
            hTransform.concat()
            
            NSColor(white: 1.0, alpha: 0.9).setFill()
            highlightPath.fill()
            NSGraphicsContext.restoreGraphicsState()
            
            // Subtle rim stroke
            NSColor(white: 1.0, alpha: 0.2).setStroke()
            let strokePath = NSBezierPath(ovalIn: circleRect)
            strokePath.lineWidth = 0.5
            strokePath.stroke()
        }
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
    func playSound(_ name: String, volume: Float = 1.0) {
        if let url = URL(fileURLWithPath: "/System/Library/Sounds/\(name).aiff") as URL? {
            if let sound = NSSound(contentsOf: url, byReference: true) {
                sound.volume = volume
                activeSounds.append(sound)
                sound.play()
                activeSounds.removeAll { !$0.isPlaying }
            }
        }
    }
    
    func triggerHaptic(_ pattern: NSHapticFeedbackManager.FeedbackPattern = .generic) {
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .now)
    }
    
    override func touchesBegan(with event: NSEvent) { updateTouch(event: event) }
    override func touchesMoved(with event: NSEvent) { updateTouch(event: event) }
    
    override func touchesEnded(with event: NSEvent) { 
        fingerIndicator.isHidden = true 
        cancelHold()
    }
    
    override func touchesCancelled(with event: NSEvent) { 
        fingerIndicator.isHidden = true 
        cancelHold()
    }
    
    func getBubbleIndex() -> (x: Int, y: Int)? {
        let xIndex = Int(currentTouchPosition.x * CGFloat(columns))
        let yIndex = Int(currentTouchPosition.y * CGFloat(rows))
        
        if xIndex >= 0 && xIndex < columns && yIndex >= 0 && yIndex < rows {
            return (xIndex, yIndex)
        }
        return nil
    }
    
    func updateTouch(event: NSEvent) {
        if let touch = event.touches(matching: .touching, in: self).first {
            currentTouchPosition = touch.normalizedPosition
            fingerIndicator.isHidden = false
            
            let viewX = currentTouchPosition.x * self.bounds.width
            let viewY = currentTouchPosition.y * self.bounds.height
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            fingerIndicator.position = CGPoint(x: viewX, y: viewY)
            CATransaction.commit()
            
            if currentStage == 2 {
                tryPopBubble(at: getBubbleIndex())
            }
        }
    }
    
    override func pressureChange(with event: NSEvent) {
        let previousStage = currentStage
        currentStage = event.stage       
        
        if currentStage == 2 {
            tryPopBubble(at: getBubbleIndex())
        } else {
            // Finger released force pressure
            cancelHold()
        }
    }
    
    var holdingBubble: Bubble?
    
    func tryPopBubble(at index: (x: Int, y: Int)?) {
        guard let idx = index else {
            cancelHold()
            return
        }
        
        let bubble = bubbles[idx.y][idx.x]
        
        if bubble.isPopped {
            cancelHold()
            return
        }
        
        if holdingBubble !== bubble {
            cancelHold() // Cancel pinch on previous bubble
            
            if bubble.type == .regular {
                processPop(bubble: bubble)
            } else if bubble.type == .hold {
                startHold(bubble: bubble)
            }
        }
    }
    
    func startHold(bubble: Bubble) {
        holdingBubble = bubble
        bubble.isHolding = true
        triggerHaptic(.generic)
    }
    
    func cancelHold() {
        holdingBubble?.isHolding = false
        holdingBubble = nil
    }
    
    func processPop(bubble: Bubble) {
        bubble.isPopped = true
        bubble.pinchAmount = 0.0 // reset pinch
        bubble.isHolding = false
        self.needsDisplay = true
        
        playSound("Pop", volume: 1.0)
        triggerHaptic(.levelChange) // Strong thud
        
        // Auto reset
        let allPopped = bubbles.flatMap { $0 }.allSatisfy { $0.isPopped }
        if allPopped {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.resetBubbles()
            }
        }
    }
    
    func resetBubbles() {
        for row in bubbles {
            for bubble in row {
                bubble.isPopped = false
                bubble.pinchAmount = 0.0
                bubble.isHolding = false
                bubble.type = (Int.random(in: 0..<100) < 60) ? .hold : .regular
            }
        }
        self.needsDisplay = true
        playSound("Blow") 
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)

let trackpadRatio: CGFloat = 16.0 / 10.0
let width: CGFloat = 450
let height = width / trackpadRatio

let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: width, height: height),
    styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
    backing: .buffered,
    defer: false
)
window.center()
window.titleVisibility = .hidden
window.titlebarAppearsTransparent = true
window.isOpaque = false
window.backgroundColor = NSColor.clear

// Liquid Glass effect for the entire window
let effectView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: width, height: height))
effectView.blendingMode = .behindWindow 
effectView.state = .active
// .popover with a forced vibrantLight appearance creates the most translucent, clear-glass look in macOS.
// It will vividly bleed the colors of whatever wallpaper or app is directly behind it!
effectView.material = .popover
effectView.appearance = NSAppearance(named: .vibrantLight)
window.contentView = effectView

// Make the entire window extra translucent to let raw background bleed through even more
window.alphaValue = 0.92

window.makeKeyAndOrderFront(nil)
let view = BubbleWrapView(frame: effectView.bounds)
view.autoresizingMask = [.width, .height]
effectView.addSubview(view)

window.makeKeyAndOrderFront(nil)
app.activate(ignoringOtherApps: true)

view.setupBubbles()

print("Final Realistic Bubble Wrap running!")
app.run()
