import AppKit
import SwiftUI
import Combine

// MARK: - Settings & Persistence
class AppSettings: ObservableObject {
    static let shared = AppSettings()
    
    @Published var lifetimePops: Int {
        didSet { UserDefaults.standard.set(lifetimePops, forKey: "lifetimePops") }
    }
    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }
    @Published var gridSizeIndex: Int { 
        didSet { UserDefaults.standard.set(gridSizeIndex, forKey: "gridSizeIndex") }
    }
    @Published var bubbleColorTint: Int { 
        didSet { UserDefaults.standard.set(bubbleColorTint, forKey: "bubbleColorTint") }
    }
    
    init() {
        UserDefaults.standard.register(defaults: [
            "lifetimePops": 0,
            "soundEnabled": true,
            "gridSizeIndex": 1, // Medium
            "bubbleColorTint": 0 // Clear
        ])
        lifetimePops = UserDefaults.standard.integer(forKey: "lifetimePops")
        soundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
        gridSizeIndex = UserDefaults.standard.integer(forKey: "gridSizeIndex")
        bubbleColorTint = UserDefaults.standard.integer(forKey: "bubbleColorTint")
    }
}

// MARK: - SwiftUI Settings Window
struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            
            VStack(spacing: 5) {
                Text("\(settings.lifetimePops)")
                    .font(.system(size: 54, weight: .ultraLight, design: .rounded))
                    .foregroundColor(.blue)
                Text("LIFETIME POPS")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .tracking(2)
            }
            .padding(.top, 30)
            
            Divider()
                .padding(.horizontal, 30)
            
            Form {
                Toggle("Sound Effects", isOn: $settings.soundEnabled)
                    .toggleStyle(.switch)
                
                Picker("Grid Size", selection: $settings.gridSizeIndex) {
                    Text("Small").tag(0)
                    Text("Medium").tag(1)
                    Text("Large").tag(2)
                }
                .pickerStyle(.segmented)
                
                Picker("Plastic Tint", selection: $settings.bubbleColorTint) {
                    Text("Clear").tag(0)
                    Text("Red").tag(1)
                    Text("Blue").tag(2)
                    Text("Green").tag(3)
                }
            }
            .padding(.horizontal, 50)
            
            Divider()
                .padding(.horizontal, 30)
            
            HStack(spacing: 15) {
                Button("Reset Stats") {
                    settings.lifetimePops = 0
                }
                
                Button("Apply & Reload Board") {
                    NotificationCenter.default.post(name: NSNotification.Name("ReloadBoard"), object: nil)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(.bottom, 30)
        }
        .frame(width: 400)
    }
}

// MARK: - Core Logic
enum BubbleType {
    case regular
    case hold
}

class Bubble {
    var rect: NSRect
    var isPopped = false
    var type: BubbleType
    var isHolding = false
    var pinchAmount: CGFloat = 0.0
    
    init(rect: NSRect, type: BubbleType) {
        self.rect = rect
        self.type = type
    }
}

class BubbleWrapView: NSView {
    var columns: Int = 8
    var rows: Int = 5
    var bubbles: [[Bubble]] = []
    
    var currentTouchPosition: NSPoint = .zero
    var currentStage = 0
    var trackingArea: NSTrackingArea?
    
    let fingerIndicator = CAShapeLayer()
    var activeSounds: [NSSound] = []
    var animationTimer: Timer?
    
    override var acceptsFirstResponder: Bool { return true }
    
    override init(frame: NSRect) {
        super.init(frame: frame)
        self.acceptsTouchEvents = true
        self.wantsLayer = true
        
        let indicatorSize: CGFloat = 20
        fingerIndicator.frame = NSRect(x: 0, y: 0, width: indicatorSize, height: indicatorSize)
        fingerIndicator.path = CGPath(ellipseIn: NSRect(x: -indicatorSize/2, y: -indicatorSize/2, width: indicatorSize, height: indicatorSize), transform: nil)
        fingerIndicator.fillColor = NSColor.white.withAlphaComponent(0.25).cgColor
        fingerIndicator.shadowColor = NSColor.black.cgColor
        fingerIndicator.shadowOpacity = 0.4
        fingerIndicator.shadowRadius = 4
        fingerIndicator.shadowOffset = .zero
        fingerIndicator.zPosition = 100
        fingerIndicator.isHidden = true
        self.layer?.addSublayer(fingerIndicator)
        
        // Setup based on settings
        switch AppSettings.shared.gridSizeIndex {
        case 0: columns = 8; rows = 5
        case 1: columns = 10; rows = 6
        case 2: columns = 16; rows = 10
        default: columns = 8; rows = 5
        }
        
        setupBubbles()
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
                        bubble.pinchAmount += 1.0 / 40.0
                        needsRedraw = true
                        if bubble.pinchAmount >= 1.0 {
                            bubble.isHolding = false
                            processPop(bubble: bubble)
                        }
                    }
                } else if !bubble.isHolding && bubble.pinchAmount > 0.0 && !bubble.isPopped {
                    bubble.pinchAmount -= 1.0 / 10.0
                    if bubble.pinchAmount < 0.0 { bubble.pinchAmount = 0.0 }
                    needsRedraw = true
                }
            }
        }
        if needsRedraw { self.needsDisplay = true }
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
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC key
            self.window?.close()
        } else {
            super.keyDown(with: event)
        }
    }
    
    func setupBubbles() {
        let bubbleWidth = self.bounds.width / CGFloat(columns)
        let bubbleHeight = self.bounds.height / CGFloat(rows)
        bubbles.removeAll()
        
        for y in 0..<rows {
            var rowBubbles: [Bubble] = []
            for x in 0..<columns {
                let rect = NSRect(x: CGFloat(x) * bubbleWidth, 
                                  y: CGFloat(y) * bubbleHeight, 
                                  width: bubbleWidth, 
                                  height: bubbleHeight)
                
                let isHold = Int.random(in: 0..<100) < 60 
                rowBubbles.append(Bubble(rect: rect, type: isHold ? .hold : .regular))
            }
            bubbles.append(rowBubbles)
        }
    }
    
    func getTint() -> NSColor {
        switch AppSettings.shared.bubbleColorTint {
        case 1: return NSColor.systemRed
        case 2: return NSColor.systemBlue
        case 3: return NSColor.systemGreen
        default: return NSColor.white
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        let tint = getTint()
        tint.withAlphaComponent(0.05).setFill()
        dirtyRect.fill()
        
        for row in bubbles {
            for bubble in row {
                if dirtyRect.intersects(bubble.rect) {
                    drawBubble(bubble, tint: tint)
                }
            }
        }
    }
    
    func drawBubble(_ bubble: Bubble, tint: NSColor) {
        let padding: CGFloat = 4
        let circleRect = bubble.rect.insetBy(dx: padding, dy: padding)
        
        NSGraphicsContext.saveGraphicsState()
        
        if bubble.pinchAmount > 0.0 && !bubble.isPopped {
            let center = CGPoint(x: circleRect.midX, y: circleRect.midY)
            let transform = NSAffineTransform()
            transform.translateX(by: center.x, yBy: center.y)
            let scaleX = 1.0 - (0.35 * bubble.pinchAmount)
            let scaleY = 1.0 + (0.15 * bubble.pinchAmount)
            transform.scaleX(by: scaleX, yBy: scaleY)
            transform.translateX(by: -center.x, yBy: -center.y)
            transform.concat()
        }
        
        if bubble.isPopped {
            tint.withAlphaComponent(0.05).setFill()
            NSBezierPath(ovalIn: circleRect).fill()
            
            NSColor(white: 1.0, alpha: 0.15).setStroke()
            let path = NSBezierPath(ovalIn: circleRect)
            path.lineWidth = 1.0
            path.stroke()
            
            let crinkle = NSBezierPath()
            crinkle.move(to: NSPoint(x: circleRect.minX + 8, y: circleRect.midY + 3))
            crinkle.line(to: NSPoint(x: circleRect.midX - 3, y: circleRect.midY - 5))
            crinkle.line(to: NSPoint(x: circleRect.maxX - 6, y: circleRect.midY + 4))
            NSColor(white: 1.0, alpha: 0.25).setStroke()
            crinkle.lineWidth = 0.5
            crinkle.stroke()
        } else {
            tint.withAlphaComponent(0.15).setFill()
            NSBezierPath(ovalIn: circleRect).fill()
            
            let lightGradient = NSGradient(starting: NSColor(white: 1.0, alpha: 0.6), ending: NSColor(white: 1.0, alpha: 0.0))
            lightGradient?.draw(in: NSBezierPath(ovalIn: circleRect), relativeCenterPosition: NSPoint(x: -0.3, y: 0.3))
            
            let darkGradient = NSGradient(starting: NSColor(white: 0.0, alpha: 0.0), ending: NSColor(white: 0.0, alpha: 0.2))
            darkGradient?.draw(in: NSBezierPath(ovalIn: circleRect), relativeCenterPosition: NSPoint(x: 0.3, y: -0.3))
            
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
            
            NSColor(white: 1.0, alpha: 0.2).setStroke()
            let strokePath = NSBezierPath(ovalIn: circleRect)
            strokePath.lineWidth = 0.5
            strokePath.stroke()
        }
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
    func playSound(_ name: String, volume: Float = 1.0) {
        if !AppSettings.shared.soundEnabled { return }
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
            cancelHold()
            
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
        bubble.pinchAmount = 0.0 
        bubble.isHolding = false
        self.needsDisplay = true
        
        // INCREMENT LIFETIME SCORE!
        AppSettings.shared.lifetimePops += 1
        
        playSound("Pop", volume: 1.0)
        triggerHaptic(.levelChange) 
        
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

// MARK: - App Delegate & Menu Bar
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popCounterMenuItem: NSMenuItem!
    
    var bubbleWindow: NSWindow?
    var settingsWindow: NSWindow?
    var cancellable: AnyCancellable?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.title = "🫧" 
            button.font = NSFont.systemFont(ofSize: 18)
        }
        
        let menu = NSMenu()
        
        popCounterMenuItem = NSMenuItem(title: "Lifetime Pops: \(AppSettings.shared.lifetimePops)", action: nil, keyEquivalent: "")
        popCounterMenuItem.isEnabled = false
        menu.addItem(popCounterMenuItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Play Bubble Wrap", action: #selector(showBubbleWrap), keyEquivalent: "p"))
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
        
        cancellable = AppSettings.shared.$lifetimePops.sink { [weak self] newCount in
            self?.popCounterMenuItem.title = "Lifetime Pops: \(newCount)"
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("ReloadBoard"), object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }
            guard let win = self.bubbleWindow else {
                self.showBubbleWrap()
                return
            }
            
            var width: CGFloat = 450
            if AppSettings.shared.gridSizeIndex == 1 { width = 550 }
            if AppSettings.shared.gridSizeIndex == 2 { width = 850 }
            let trackpadRatio: CGFloat = 16.0 / 10.0
            let height = width / trackpadRatio
            
            let oldCenter = CGPoint(x: win.frame.midX, y: win.frame.midY)
            win.setFrame(NSRect(x: 0, y: 0, width: width, height: height), display: true)
            win.setFrameOrigin(NSPoint(x: oldCenter.x - width/2, y: oldCenter.y - height/2))
            
            if let effectView = win.contentView as? NSVisualEffectView,
               let bubbleView = effectView.subviews.first as? BubbleWrapView {
                switch AppSettings.shared.gridSizeIndex {
                case 0: bubbleView.columns = 8; bubbleView.rows = 5
                case 1: bubbleView.columns = 10; bubbleView.rows = 6
                case 2: bubbleView.columns = 16; bubbleView.rows = 10
                default: bubbleView.columns = 8; bubbleView.rows = 5
                }
                bubbleView.setupBubbles()
                bubbleView.needsDisplay = true
            }
        }
        
        // Launch bubble wrap automatically on start
        showBubbleWrap()
    }
    
    @objc func showBubbleWrap() {
        if bubbleWindow == nil {
            let trackpadRatio: CGFloat = 16.0 / 10.0
            
            // Adjust window size based on grid setting so bubbles are reasonably sized
            var width: CGFloat = 450
            if AppSettings.shared.gridSizeIndex == 1 { width = 550 }
            if AppSettings.shared.gridSizeIndex == 2 { width = 850 }
            
            let height = width / trackpadRatio
            
            let win = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: width, height: height),
                styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            win.center()
            win.titleVisibility = .hidden
            win.titlebarAppearsTransparent = true
            win.isOpaque = false
            win.backgroundColor = NSColor.clear
            win.alphaValue = 0.92
            
            let effectView = NSVisualEffectView(frame: win.contentRect(forFrameRect: win.frame))
            effectView.blendingMode = .behindWindow 
            effectView.state = .active
            effectView.material = .popover
            effectView.appearance = NSAppearance(named: .vibrantLight)
            win.contentView = effectView
            
            let view = BubbleWrapView(frame: effectView.bounds)
            view.autoresizingMask = [.width, .height]
            effectView.addSubview(view)
            
            bubbleWindow = win
            
            NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: win, queue: nil) { [weak self] _ in
                self?.bubbleWindow = nil
            }
        }
        bubbleWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func showSettings() {
        if settingsWindow == nil {
            let hostingController = NSHostingController(rootView: SettingsView())
            let win = NSWindow(contentViewController: hostingController)
            win.title = "Bubble Wrap Settings"
            win.styleMask = [.titled, .closable]
            win.center()
            settingsWindow = win
            
            NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: win, queue: nil) { [weak self] _ in
                self?.settingsWindow = nil
            }
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
// .accessory makes it a purely menu-bar app (no dock icon)
app.setActivationPolicy(.accessory)
app.run()
