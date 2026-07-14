import AppKit

enum BubbleType {
    case regular
    case stubborn
}

class Bubble {
    var rect: NSRect
    var isPopped = false
    var type: BubbleType
    var health: Int
    var squish: CGFloat = 1.0
    
    init(rect: NSRect, type: BubbleType, health: Int) {
        self.rect = rect
        self.type = type
        self.health = health
    }
}

class BubbleWrapView: NSView {
    // Reduced bubbles for a quicker "time-wasting" session
    let columns = 8 
    let rows = 5
    var bubbles: [[Bubble]] = []
    
    var currentTouchPosition: NSPoint = .zero
    var currentStage = 0
    var trackingArea: NSTrackingArea?
    
    let fingerIndicator = CAShapeLayer()
    var activeSounds: [NSSound] = []
    
    override var acceptsFirstResponder: Bool { return true }
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        self.acceptsTouchEvents = true
        
        let indicatorSize: CGFloat = 20
        fingerIndicator.frame = NSRect(x: -100, y: -100, width: indicatorSize, height: indicatorSize)
        fingerIndicator.path = CGPath(ellipseIn: NSRect(x: 0, y: 0, width: indicatorSize, height: indicatorSize), transform: nil)
        // Soft white glow for the finger
        fingerIndicator.fillColor = NSColor.white.withAlphaComponent(0.3).cgColor
        fingerIndicator.shadowColor = NSColor.black.cgColor
        fingerIndicator.shadowOpacity = 0.5
        fingerIndicator.shadowRadius = 5
        fingerIndicator.shadowOffset = .zero
        fingerIndicator.zPosition = 100
        
        self.wantsLayer = true
        self.layer?.addSublayer(fingerIndicator)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
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
                
                let isStubborn = Int.random(in: 0..<100) < 15 // 15% stubborn
                let health = isStubborn ? Int.random(in: 2...4) : 1
                
                let bubble = Bubble(rect: rect, type: isStubborn ? .stubborn : .regular, health: health)
                rowBubbles.append(bubble)
            }
            bubbles.append(rowBubbles)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        // Very faint plastic sheet over everything to tie the bubbles together.
        // We removed the cardboard so the liquid glass effect shines through!
        NSColor(white: 1.0, alpha: 0.05).setFill()
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
        let padding: CGFloat = 4 // slightly more padding for fewer bubbles
        let circleRect = bubble.rect.insetBy(dx: padding, dy: padding)
        
        NSGraphicsContext.saveGraphicsState()
        
        if bubble.squish != 1.0 {
            let center = CGPoint(x: circleRect.midX, y: circleRect.midY)
            let transform = NSAffineTransform()
            transform.translateX(by: center.x, yBy: center.y)
            transform.scaleX(by: 1.0, yBy: bubble.squish)
            transform.translateX(by: -center.x, yBy: -center.y)
            transform.concat()
        }
        
        if bubble.isPopped {
            // Wrinkled clear plastic look
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
            // 3D Clear Plastic Bubble
            
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
    
    func playSound(_ name: String) {
        if let url = URL(fileURLWithPath: "/System/Library/Sounds/\(name).aiff") as URL? {
            if let sound = NSSound(contentsOf: url, byReference: true) {
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
            fingerIndicator.position = CGPoint(x: viewX - 10, y: viewY - 10)
            CATransaction.commit()
            
            if currentStage == 2 { tryPopBubble() }
        }
    }
    
    override func pressureChange(with event: NSEvent) {
        let previousStage = currentStage
        currentStage = event.stage       
        if currentStage == 2 && previousStage < 2 {
            tryPopBubble()
        } else if currentStage == 2 {
            tryPopBubble()
        }
    }
    
    var isProcessingPop = false
    
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
    
    func processPop(bubble: Bubble) {
        if isProcessingPop { return }
        
        if bubble.health > 1 {
            bubble.health -= 1
            bubble.squish = 0.8
            self.needsDisplay = true
            
            triggerHaptic(.generic) 
            
            isProcessingPop = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.isProcessingPop = false
                bubble.squish = 1.0
                self.needsDisplay = true
            }
        } else {
            bubble.isPopped = true
            self.needsDisplay = true
            playSound("Pop") 
            triggerHaptic(.levelChange)
            
            // Check win condition to auto-reset
            let allPopped = bubbles.flatMap { $0 }.allSatisfy { $0.isPopped }
            if allPopped {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.resetBubbles()
                }
            }
        }
    }
    
    func resetBubbles() {
        for row in bubbles {
            for bubble in row {
                bubble.isPopped = false
                bubble.health = (Int.random(in: 0..<100) < 15) ? Int.random(in: 2...4) : 1
            }
        }
        self.needsDisplay = true
        // satisfying swoosh sound on reset
        playSound("Blow") 
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)

let trackpadRatio: CGFloat = 16.0 / 10.0
let width: CGFloat = 450
let height = width / trackpadRatio

// Use fullSizeContentView and hidden title to make it completely borderless glass
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
window.backgroundColor = NSColor.clear // Essential for the glass effect

// Create the macOS Liquid Glass / Frosted effect view
let effectView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: width, height: height))
effectView.blendingMode = .behindWindow // Blends with whatever is behind the window on the desktop
effectView.state = .active
effectView.material = .hudWindow // A beautiful dark translucent glass.
window.contentView = effectView

let view = BubbleWrapView(frame: effectView.bounds)
view.autoresizingMask = [.width, .height]
effectView.addSubview(view)

window.makeKeyAndOrderFront(nil)
app.activate(ignoringOtherApps: true)

view.setupBubbles()

print("Liquid Glass Bubble Wrap running!")
app.run()
