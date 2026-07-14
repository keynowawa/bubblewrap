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
    let columns = 12
    let rows = 8
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
        fingerIndicator.fillColor = NSColor.white.withAlphaComponent(0.25).cgColor
        fingerIndicator.shadowColor = NSColor.black.cgColor
        fingerIndicator.shadowOpacity = 0.3
        fingerIndicator.shadowRadius = 4
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
                
                // Realistic distribution: mostly regular, a few that are hard to pop
                let isStubborn = Int.random(in: 0..<100) < 15 // 15% stubborn
                let health = isStubborn ? Int.random(in: 2...4) : 1
                
                let bubble = Bubble(rect: rect, type: isStubborn ? .stubborn : .regular, health: health)
                rowBubbles.append(bubble)
            }
            bubbles.append(rowBubbles)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        // 1. Cardboard Background
        NSColor(calibratedRed: 0.8, green: 0.68, blue: 0.5, alpha: 1.0).setFill()
        dirtyRect.fill()
        
        // 2. Translucent Plastic Base Layer
        NSColor(white: 1.0, alpha: 0.15).setFill()
        dirtyRect.fill()
        
        // 3. Draw each bubble
        for row in bubbles {
            for bubble in row {
                if dirtyRect.intersects(bubble.rect) {
                    drawBubble(bubble)
                }
            }
        }
    }
    
    func drawBubble(_ bubble: Bubble) {
        let padding: CGFloat = 3
        let circleRect = bubble.rect.insetBy(dx: padding, dy: padding)
        
        NSGraphicsContext.saveGraphicsState()
        
        // Handle physical squish animation when pressed
        if bubble.squish != 1.0 {
            let center = CGPoint(x: circleRect.midX, y: circleRect.midY)
            let transform = NSAffineTransform()
            transform.translateX(by: center.x, yBy: center.y)
            transform.scaleX(by: 1.0, yBy: bubble.squish)
            transform.translateX(by: -center.x, yBy: -center.y)
            transform.concat()
        }
        
        if bubble.isPopped {
            // Popped, wrinkled clear plastic look
            NSColor(white: 0.9, alpha: 0.05).setFill()
            NSBezierPath(ovalIn: circleRect).fill()
            
            NSColor(white: 1.0, alpha: 0.15).setStroke()
            let path = NSBezierPath(ovalIn: circleRect)
            path.lineWidth = 1.0
            path.stroke()
            
            // Random inner wrinkles
            let crinkle = NSBezierPath()
            crinkle.move(to: NSPoint(x: circleRect.minX + 6, y: circleRect.midY + 2))
            crinkle.line(to: NSPoint(x: circleRect.midX - 2, y: circleRect.midY - 4))
            crinkle.line(to: NSPoint(x: circleRect.maxX - 5, y: circleRect.midY + 3))
            NSColor(white: 1.0, alpha: 0.25).setStroke()
            crinkle.lineWidth = 0.5
            crinkle.stroke()
        } else {
            // 3D Clear Plastic Bubble
            
            // Base milky fill
            NSColor(white: 0.95, alpha: 0.2).setFill()
            NSBezierPath(ovalIn: circleRect).fill()
            
            // Top-left bright reflection
            let lightGradient = NSGradient(starting: NSColor(white: 1.0, alpha: 0.8), ending: NSColor(white: 1.0, alpha: 0.0))
            lightGradient?.draw(in: NSBezierPath(ovalIn: circleRect), relativeCenterPosition: NSPoint(x: -0.3, y: 0.3))
            
            // Bottom-right inner shadow for depth
            let darkGradient = NSGradient(starting: NSColor(white: 0.0, alpha: 0.0), ending: NSColor(white: 0.0, alpha: 0.25))
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
            // Stubborn: squish but don't pop
            bubble.health -= 1
            bubble.squish = 0.8
            self.needsDisplay = true
            
            // Only fire a soft haptic, NO extra sound. The physical trackpad click acts as the thud.
            triggerHaptic(.generic) 
            
            isProcessingPop = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.isProcessingPop = false
                bubble.squish = 1.0
                self.needsDisplay = true
            }
        } else {
            // Pop!
            bubble.isPopped = true
            self.needsDisplay = true
            playSound("Pop") // A clean, standard pop
            triggerHaptic(.levelChange) // A deep haptic thump
        }
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)

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
window.title = "Realistic Bubble Wrap"
window.backgroundColor = NSColor.black

let view = BubbleWrapView(frame: window.contentRect(forFrameRect: window.frame))
window.contentView = view

window.makeKeyAndOrderFront(nil)
app.activate(ignoringOtherApps: true)

view.setupBubbles()

print("Realistic Bubble Wrap running!")
app.run()
