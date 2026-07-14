import AppKit

enum BubbleType {
    case regular
    case hold
}

class Bubble {
    let indexX: Int
    let indexY: Int
    var isPopped = false
    var type: BubbleType
    
    let containerLayer = CALayer()
    let baseLayer = CAShapeLayer()
    let highlightLayer = CAShapeLayer()
    let ringLayer = CAShapeLayer() // for the pop ripple
    
    init(x: Int, y: Int, rect: NSRect, type: BubbleType) {
        self.indexX = x
        self.indexY = y
        self.type = type
        
        containerLayer.frame = rect
        
        let padding: CGFloat = 6
        let circleRect = NSRect(x: padding, y: padding, width: rect.width - padding*2, height: rect.height - padding*2)
        let path = CGPath(ellipseIn: circleRect, transform: nil)
        
        // Base glass plastic layer
        baseLayer.path = path
        if type == .hold {
            // Hold bubbles have a subtle blue tint
            baseLayer.fillColor = NSColor(calibratedRed: 0.5, green: 0.8, blue: 1.0, alpha: 0.3).cgColor
        } else {
            baseLayer.fillColor = NSColor.white.withAlphaComponent(0.15).cgColor
        }
        baseLayer.strokeColor = NSColor.white.withAlphaComponent(0.4).cgColor
        baseLayer.lineWidth = 1.0
        // Set anchor to center for scaling animations
        baseLayer.bounds = containerLayer.bounds
        baseLayer.position = CGPoint(x: containerLayer.bounds.midX, y: containerLayer.bounds.midY)
        // Offset path to match bounds
        let offsetPath = CGPath(ellipseIn: circleRect.offsetBy(dx: -containerLayer.bounds.width/2, dy: -containerLayer.bounds.height/2), transform: nil)
        baseLayer.path = offsetPath
        containerLayer.addSublayer(baseLayer)
        
        // Bright Liquid Glass Specular Highlight
        let hWidth = circleRect.width * 0.3
        let hHeight = circleRect.height * 0.15
        let hRect = NSRect(x: circleRect.minX + circleRect.width * 0.15 - containerLayer.bounds.width/2, 
                           y: circleRect.maxY - circleRect.height * 0.35 - containerLayer.bounds.height/2, 
                           width: hWidth, 
                           height: hHeight)
        
        highlightLayer.path = CGPath(ellipseIn: hRect, transform: nil)
        highlightLayer.fillColor = NSColor.white.withAlphaComponent(0.95).cgColor
        
        highlightLayer.bounds = containerLayer.bounds
        highlightLayer.position = CGPoint(x: containerLayer.bounds.midX, y: containerLayer.bounds.midY)
        highlightLayer.transform = CATransform3DMakeRotation(25 * .pi / 180, 0, 0, 1)
        containerLayer.addSublayer(highlightLayer)
        
        // Minimalist Ripple Ring (hidden initially)
        ringLayer.path = offsetPath
        ringLayer.fillColor = NSColor.clear.cgColor
        ringLayer.strokeColor = NSColor.white.withAlphaComponent(0.8).cgColor
        ringLayer.lineWidth = 1.5
        ringLayer.opacity = 0
        ringLayer.bounds = containerLayer.bounds
        ringLayer.position = CGPoint(x: containerLayer.bounds.midX, y: containerLayer.bounds.midY)
        containerLayer.addSublayer(ringLayer)
    }
    
    func animatePop() {
        self.isPopped = true
        
        // Commit final states so it stays this way after animation
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.baseLayer.opacity = 0.1
        self.baseLayer.transform = CATransform3DMakeScale(0.8, 0.8, 1.0)
        self.baseLayer.strokeColor = NSColor.white.withAlphaComponent(0.1).cgColor
        self.highlightLayer.opacity = 0.0
        CATransaction.commit()
        
        // 1. Pop Scale Down (Spring)
        let scaleAnim = CASpringAnimation(keyPath: "transform.scale")
        scaleAnim.fromValue = 1.0
        scaleAnim.toValue = 0.8
        scaleAnim.damping = 15
        scaleAnim.initialVelocity = 5
        scaleAnim.duration = scaleAnim.settlingDuration
        baseLayer.add(scaleAnim, forKey: "popScale")
        
        let fadeAnim = CABasicAnimation(keyPath: "opacity")
        fadeAnim.fromValue = 1.0
        fadeAnim.toValue = 0.1
        fadeAnim.duration = 0.2
        baseLayer.add(fadeAnim, forKey: "popFade")
        
        let hlFade = CABasicAnimation(keyPath: "opacity")
        hlFade.fromValue = 0.95
        hlFade.toValue = 0.0
        hlFade.duration = 0.15
        highlightLayer.add(hlFade, forKey: "hlFade")
        
        // 2. Minimalist Shockwave Ripple
        let ringScale = CASpringAnimation(keyPath: "transform.scale")
        ringScale.fromValue = 0.9
        ringScale.toValue = 1.6
        ringScale.damping = 12
        ringScale.duration = 0.6
        
        let ringFade = CABasicAnimation(keyPath: "opacity")
        ringFade.fromValue = 0.8
        ringFade.toValue = 0.0
        ringFade.duration = 0.5
        
        ringLayer.add(ringScale, forKey: "ringScale")
        ringLayer.add(ringFade, forKey: "ringFade")
    }
    
    func animateHoldStart() {
        // Tremble / build up animation
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 1.0
        scale.toValue = 0.85
        scale.duration = 0.8
        scale.fillMode = .forwards
        scale.isRemovedOnCompletion = false
        baseLayer.add(scale, forKey: "holdScale")
        
        let pulse = CABasicAnimation(keyPath: "opacity")
        pulse.fromValue = 0.3
        pulse.toValue = 0.8
        pulse.duration = 0.15
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        baseLayer.add(pulse, forKey: "holdPulse")
    }
    
    func animateHoldCancel() {
        baseLayer.removeAnimation(forKey: "holdScale")
        baseLayer.removeAnimation(forKey: "holdPulse")
        
        // Bounce back
        let scale = CASpringAnimation(keyPath: "transform.scale")
        scale.toValue = 1.0
        scale.damping = 12
        scale.initialVelocity = 10
        scale.duration = scale.settlingDuration
        baseLayer.add(scale, forKey: "cancelScale")
    }
    
    func reset() {
        isPopped = false
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.baseLayer.opacity = 1.0
        self.baseLayer.transform = CATransform3DIdentity
        self.baseLayer.strokeColor = NSColor.white.withAlphaComponent(0.4).cgColor
        self.highlightLayer.opacity = 1.0
        self.ringLayer.opacity = 0.0
        CATransaction.commit()
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
    
    override var acceptsFirstResponder: Bool { return true }
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        self.acceptsTouchEvents = true
        self.wantsLayer = true
        
        let indicatorSize: CGFloat = 24
        fingerIndicator.frame = NSRect(x: 0, y: 0, width: indicatorSize, height: indicatorSize)
        fingerIndicator.path = CGPath(ellipseIn: NSRect(x: -indicatorSize/2, y: -indicatorSize/2, width: indicatorSize, height: indicatorSize), transform: nil)
        fingerIndicator.fillColor = NSColor.white.withAlphaComponent(0.15).cgColor
        fingerIndicator.shadowColor = NSColor.black.cgColor
        fingerIndicator.shadowOpacity = 0.3
        fingerIndicator.shadowRadius = 8
        fingerIndicator.shadowOffset = .zero
        fingerIndicator.zPosition = 100
        fingerIndicator.isHidden = true
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
                
                let isHold = Int.random(in: 0..<100) < 20 // 20% require holding
                let bubble = Bubble(x: x, y: y, rect: rect, type: isHold ? .hold : .regular)
                self.layer?.addSublayer(bubble.containerLayer)
                rowBubbles.append(bubble)
            }
            bubbles.append(rowBubbles)
        }
        self.layer?.addSublayer(fingerIndicator) // ensure it stays on top
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
    var activeHoldItem: DispatchWorkItem?
    
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
        
        // If we drag our finger onto a new bubble while still force-pressing
        if holdingBubble !== bubble {
            cancelHold() // Cancel any ongoing hold
            
            if bubble.type == .regular {
                processPop(bubble: bubble)
            } else if bubble.type == .hold {
                startHold(bubble: bubble)
            }
        }
    }
    
    func startHold(bubble: Bubble) {
        holdingBubble = bubble
        bubble.animateHoldStart()
        
        triggerHaptic(.generic)
        
        let item = DispatchWorkItem { [weak self] in
            guard let self = self, self.holdingBubble === bubble else { return }
            self.processPop(bubble: bubble)
            self.holdingBubble = nil
        }
        activeHoldItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: item) // 0.8 seconds to hold
    }
    
    func cancelHold() {
        activeHoldItem?.cancel()
        activeHoldItem = nil
        
        if let b = holdingBubble {
            b.animateHoldCancel()
            holdingBubble = nil
        }
    }
    
    func processPop(bubble: Bubble) {
        bubble.animatePop()
        
        playSound("Pop", volume: 0.8)
        
        if bubble.type == .hold {
            // Extra satisfying deep thud for hold bubbles
            triggerHaptic(.alignment)
            playSound("Basso", volume: 0.4) 
        } else {
            triggerHaptic(.levelChange)
        }
        
        // Check win condition
        let allPopped = bubbles.flatMap { $0 }.allSatisfy { $0.isPopped }
        if allPopped {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self.resetBubbles()
            }
        }
    }
    
    func resetBubbles() {
        for row in bubbles {
            for bubble in row {
                bubble.reset()
                bubble.type = (Int.random(in: 0..<100) < 20) ? .hold : .regular
                if bubble.type == .hold {
                    bubble.baseLayer.fillColor = NSColor(calibratedRed: 0.5, green: 0.8, blue: 1.0, alpha: 0.3).cgColor
                } else {
                    bubble.baseLayer.fillColor = NSColor.white.withAlphaComponent(0.15).cgColor
                }
            }
        }
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

// Liquid Glass effect
let effectView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: width, height: height))
effectView.blendingMode = .behindWindow 
effectView.state = .active
effectView.material = .popover // .popover gives a brilliant, highly translucent bright glass look
window.contentView = effectView

let view = BubbleWrapView(frame: effectView.bounds)
view.autoresizingMask = [.width, .height]
effectView.addSubview(view)

window.makeKeyAndOrderFront(nil)
app.activate(ignoringOtherApps: true)

view.setupBubbles()

print("Liquid Glass Animated Bubble Wrap running!")
app.run()
