import SwiftUI
import SceneKit
import Combine

/// Main experience: 3D scene + pan/zoom gestures + overlay HUD.
struct ExperienceView: View {
    @EnvironmentObject var scaleEngine: ScaleEngine
    @EnvironmentObject var hapticManager: HapticManager
    @EnvironmentObject var soundManager: SoundManager
    
    @StateObject private var scene = UniverseScene()
    
    // Gesture States
    @State private var lastMagnification: CGFloat = 1.0
    @State private var lastDragTranslation: CGSize = .zero
    
    // UI States
    @State private var levelChangeId = 0
    @State private var userIsExploring = false // tracks if camera is physically moved
    @State private var selectedElement: ScaleElement? = nil // Tapped 3D sub-element
    
    // Zooming state for side panel
    @State private var isZooming = false
    @State private var zoomTimer: Timer?
    
    // New Idle State for UI Overlays
    @State private var isIdle = false
    @State private var idleTimer: Timer?
    @State private var userDismissedPanel = false
    
    var body: some View {
        ZStack {
            // === 3D SCENE ===
            InteractiveSceneView(
                scene: scene,
                pointOfView: scene.cameraNode
            ) { hitNodeName in
                hapticManager.playTap()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    if let name = hitNodeName, let element = ScaleElement.allElements[name] {
                        selectedElement = element
                    } else {
                        selectedElement = nil
                    }
                }
            }
            .ignoresSafeArea()
            .gesture(
                SimultaneousGesture(
                    pinchGesture,
                    dragGesture
                )
            )
            
            // === HUD OVERLAYS ===
            
            // Top-right: scale indicator
            VStack {
                HStack {
                    Spacer()
                    scaleIndicator
                        .padding(.top, 60)
                        .padding(.trailing, 16)
                }
                Spacer()
            }
            
            // Left: journey bar
            HStack {
                journeyBar
                    .padding(.leading, 10)
                    .padding(.vertical, 100)
                Spacer()
            }
            
            // Right: Side Glass Panel (Activates when stopped zooming near anchor)
            HStack {
                Spacer()
                if shouldShowSidePanel {
                    sideGlassPanel
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .padding(.trailing, 20)
                }
            }
            
            // Bottom: level info + info card
            VStack {
                Spacer()
                
                // Explored reset button
                if userIsExploring {
                    Button(action: {
                        scene.resetCamera()
                        withAnimation { userIsExploring = false }
                        hapticManager.playTap()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "scope")
                            Text("Re-center")
                        }
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(.ultraThinMaterial).opacity(0.8))
                        .foregroundColor(.white)
                    }
                    .padding(.bottom, 20)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                // Current level display
                levelDisplay
                    .id(levelChangeId)
                
                // Interaction hint
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.left.and.arrow.up.right")
                        Text("pinch to scale")
                    }
                    Text("•").opacity(0.3)
                    HStack(spacing: 4) {
                        Image(systemName: "hand.draw")
                        Text("drag to look")
                    }
                }
                .font(.system(size: 9, weight: .light))
                .tracking(1)
                .foregroundColor(.white.opacity(0.3))
                .padding(.bottom, 25)
            }
            
            // Element Info Override (If user tapped a sub-element)
            if let el = selectedElement {
                VStack {
                    Spacer()
                    elementCard(el)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 80)
                }
            }
            
            // Boundary message (Final Philosophy)
            if scaleEngine.currentExponent == 0 {
                VStack {
                    Text("You exist between infinities.")
                        .font(.system(size: 14, weight: .medium))
                        .tracking(1.5)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 22)
                        .background(Capsule().fill(.ultraThinMaterial).opacity(0.8))
                        .padding(.top, 130)
                    Spacer()
                }
                .transition(.opacity)
            } else if scaleEngine.isAtBoundary {
                VStack {
                    Text(scaleEngine.currentExponent <= ScaleEngine.minExponent + 0.1
                         ? "The quantum limit"
                         : "The edge of the observable universe")
                        .font(.system(size: 13, weight: .medium))
                        .tracking(1)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .background(Capsule().fill(.ultraThinMaterial).opacity(0.8))
                        .padding(.top, 130)
                    Spacer()
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            scene.updateZoom(exponent: scaleEngine.currentExponent)
            resetIdleTimer()
        }
        .onChange(of: scaleEngine.currentLevel.id) {
            levelChangeId += 1
            userDismissedPanel = false // Allow new level panel to appear
            if selectedElement != nil {
                withAnimation { selectedElement = nil }
            }
        }
    }
    
    // MARK: - Panel Logic
    private var shouldShowSidePanel: Bool {
        // Show side panel if we are idle for 1s, close to the anchor, user hasn't dismissed it, and no element is selected
        let dist = abs(scaleEngine.currentExponent - scaleEngine.currentLevel.exponent)
        return isIdle && dist < 0.6 && !userDismissedPanel && selectedElement == nil
    }
    
    private func resetIdleTimer() {
        isIdle = false
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isIdle = true
            }
        }
    }
    
    // MARK: - Gestures
    
    private var pinchGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                // Debounce zooming status
                if !isZooming { withAnimation(.easeInOut(duration: 0.2)) { isZooming = true } }
                zoomTimer?.invalidate()
                
                let current = value.magnification
                let delta = log2(current / lastMagnification)
                lastMagnification = current
                
                scaleEngine.applyZoomDelta(delta * 10.0)
                scene.updateZoom(exponent: scaleEngine.currentExponent)
                soundManager.updateForExponent(scaleEngine.currentExponent)
                
                resetIdleTimer() // Reset idle timer when interacting
                
                // Restart timer to reset zoom
                zoomTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isZooming = false
                    }
                }
            }
            .onEnded { _ in 
                lastMagnification = 1.0 
                zoomTimer?.invalidate()
                zoomTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isZooming = false
                    }
                }
            }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                userIsExploring = true
                let trans = value.translation
                let dx = Float(trans.width - lastDragTranslation.width)
                let dy = Float(trans.height - lastDragTranslation.height)
                lastDragTranslation = trans
                scene.rotateCamera(dx: dx, dy: dy)
                resetIdleTimer() // Reset idle timer when exploring
            }
            .onEnded { _ in lastDragTranslation = .zero }
    }
    
    // MARK: - Scale Indicator
    
    private var scaleIndicator: some View {
        VStack(alignment: .trailing, spacing: 5) {
            HStack(spacing: 1) {
                Text("10")
                    .font(.system(size: 24, weight: .thin, design: .monospaced))
                    .foregroundColor(scaleEngine.exponentInt == 0 ? .yellow : .white.opacity(0.9))
                Text(formatExponent(scaleEngine.exponentInt))
                    .font(.system(size: 14, weight: .light, design: .monospaced))
                    .foregroundColor(scaleEngine.exponentInt == 0 ? .yellow : .cyan)
                    .offset(y: -7)
                Text(" m")
                    .font(.system(size: 16, weight: .ultraLight))
                    .foregroundColor(scaleEngine.exponentInt == 0 ? .yellow : .white.opacity(0.4))
            }
            .contentTransition(.numericText())
            .animation(.easeInOut(duration: 0.15), value: scaleEngine.exponentInt)
            
            Text(scaleEngine.currentLevel.measurement)
                .font(.system(size: 11, weight: .ultraLight, design: .monospaced))
                .tracking(0.5)
                .foregroundColor(.white.opacity(0.4))
            
            HStack(spacing: 4) {
                Circle().fill(scaleEngine.currentLevel.color).frame(width: 5, height: 5)
                Text(scaleEngine.currentZone.rawValue.uppercased())
                    .font(.system(size: 8, weight: .medium)).tracking(2)
                    .foregroundColor(.white.opacity(0.35))
            }
            if scaleEngine.exponentInt == 0 {
                Text("YOU ARE HERE")
                    .font(.system(size: 8, weight: .bold)).tracking(1.5)
                    .foregroundColor(.yellow.opacity(0.8))
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial).opacity(0.6))
    }
    
    // MARK: - Level Display
    
    private var levelDisplay: some View {
        VStack(spacing: 5) {
            Text(scaleEngine.currentLevel.emoji)
                .font(.system(size: 44))
                .shadow(color: scaleEngine.currentLevel.color.opacity(0.6), radius: 10)
            
            Text(scaleEngine.currentLevel.name)
                .font(.system(size: 28, weight: .thin))
                .tracking(4)
                .foregroundColor(.white)
            
            Text(scaleEngine.currentLevel.measurement)
                .font(.system(size: 13, weight: .ultraLight))
                .tracking(2)
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.bottom, 15)
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .animation(.easeInOut(duration: 0.3), value: scaleEngine.currentLevel.id)
    }
    
    // MARK: - Side Glass Panel
    
    private var sideGlassPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(scaleEngine.currentLevel.name.uppercased())
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(scaleEngine.currentLevel.color.opacity(0.8))
                    .tracking(2)
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        userDismissedPanel = true
                    }
                    hapticManager.playTap()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.5))
                        .font(.system(size: 18))
                }
            }
            
            // Layer 1 - Simple fact
            VStack(alignment: .leading, spacing: 4) {
                Text("Fact")
                    .font(.system(size: 9, weight: .bold)).tracking(1.5).foregroundColor(.white.opacity(0.4))
                Text(scaleEngine.currentLevel.fact)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white)
            }
            
            // Layer 2 - Scientific measurement
            VStack(alignment: .leading, spacing: 4) {
                Text("Measurement")
                    .font(.system(size: 9, weight: .bold)).tracking(1.5).foregroundColor(.white.opacity(0.4))
                Text(scaleEngine.currentLevel.measurement)
                    .font(.system(size: 13, weight: .light, design: .monospaced))
                    .foregroundColor(.cyan.opacity(0.9))
            }
            
            // Layer 3 - Concept explanation
            VStack(alignment: .leading, spacing: 4) {
                Text("Concept")
                    .font(.system(size: 9, weight: .bold)).tracking(1.5).foregroundColor(.white.opacity(0.4))
                Text(scaleEngine.currentLevel.concept)
                    .font(.system(size: 13, weight: .light))
                    .lineSpacing(4)
                    .foregroundColor(.white.opacity(0.75))
            }
            
            // Layer 4 - Reflective statement
            VStack(alignment: .leading, spacing: 4) {
                Text("Reflection")
                    .font(.system(size: 9, weight: .bold)).tracking(1.5).foregroundColor(.white.opacity(0.4))
                Text("\"\(scaleEngine.currentLevel.reflection)\"")
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .italic()
                    .lineSpacing(4)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(24)
        .frame(width: 300)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .opacity(0.85)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(scaleEngine.currentLevel.color.opacity(0.4), lineWidth: 0.5)
        )
    }
    
    // MARK: - Interactive Element Card (Overrides side panel if an element is clicked)
    private func elementCard(_ el: ScaleElement) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text("🔍").font(.system(size: 26))
                VStack(alignment: .leading, spacing: 2) {
                    Text(el.title)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                    Text(el.subtitle)
                        .font(.system(size: 12, weight: .light, design: .monospaced))
                        .foregroundColor(.cyan.opacity(0.8))
                }
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedElement = nil
                    }
                    hapticManager.playTap()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.5))
                        .font(.system(size: 20))
                }
            }
            Divider().background(Color.white.opacity(0.15))
            Text(el.description)
                .font(.system(size: 14, weight: .light))
                .lineSpacing(5)
                .foregroundColor(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: 340)
        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial).opacity(0.9))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.3), lineWidth: 0.5))
        .padding(.horizontal, 20)
    }
    
    // MARK: - Journey Bar
    
    private var journeyBar: some View {
        GeometryReader { geo in
            let h = geo.size.height
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 1.5).fill(Color.white.opacity(0.08)).frame(width: 3)
                
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(LinearGradient(
                        colors: [
                            Color(hue: 0.83, saturation: 0.7, brightness: 0.8), // quantum
                            Color(hue: 0.45, saturation: 0.4, brightness: 0.7), // molecular
                            .white, // human
                            Color(hue: 0.58, saturation: 0.6, brightness: 0.7), // planetary
                            Color(hue: 0.7, saturation: 0.5, brightness: 0.5) // universe
                        ], startPoint: .bottom, endPoint: .top // inverted so top is large
                    ))
                    .frame(width: 3).opacity(0.35)
                
                Circle()
                    .fill(scaleEngine.currentLevel.color)
                    .frame(width: 8, height: 8)
                    .shadow(color: scaleEngine.currentLevel.color.opacity(0.8), radius: 5)
                    .offset(x: -2.5, y: yPosition(h))
                    .animation(.easeOut(duration: 0.15), value: scaleEngine.currentExponent)
                
                ForEach(ScaleLevel.allLevels, id: \.id) { level in
                    Text(level.name.split(separator: " ").first ?? "")
                        .font(.system(size: 8, weight: .light))
                        .tracking(1)
                        .foregroundColor(.white.opacity(labelOpacity(level.exponent)))
                        .offset(x: 10, y: labelY(level.exponent, h))
                }
            }
        }
        .frame(width: 60)
    }
    
    private func yPosition(_ height: CGFloat) -> CGFloat {
        let norm = scaleEngine.journeyProgress
        return CGFloat(1.0 - norm) * (height - 10) + 5 - height / 2
    }
    
    private func labelY(_ exp: Double, _ height: CGFloat) -> CGFloat {
        let norm = (exp - ScaleEngine.minExponent) / ScaleEngine.totalRange
        return CGFloat(1.0 - norm) * (height - 10) + 5 - height / 2
    }
    
    private func labelOpacity(_ exp: Double) -> Double {
        abs(scaleEngine.currentExponent - exp) < 4 ? 0.8 : 0.2
    }
    
    private func formatExponent(_ e: Int) -> String {
        if e >= 0 { return "\(e)" }
        return "⁻\(abs(e))"
    }
}

// MARK: - Interactive Scene View

struct InteractiveSceneView: UIViewRepresentable {
    let scene: SCNScene
    let pointOfView: SCNNode?
    let onTap: (String?) -> Void
    
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = scene
        view.pointOfView = pointOfView
        view.preferredFramesPerSecond = 60
        view.antialiasingMode = .multisampling4X
        view.backgroundColor = .black
        view.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.cancelsTouchesInView = false 
        view.addGestureRecognizer(tap)
        
        return view
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        uiView.scene = scene
        uiView.pointOfView = pointOfView
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: InteractiveSceneView
        init(_ parent: InteractiveSceneView) { self.parent = parent }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let view = gesture.view as? SCNView else { return }
            let location = gesture.location(in: view)
            
            let hits = view.hitTest(location, options: [
                SCNHitTestOption.searchMode: SCNHitTestSearchMode.closest.rawValue
            ])
            
            for hit in hits {
                var node: SCNNode? = hit.node
                for _ in 0..<3 {
                    if let n = node?.name, n.hasPrefix("element_") {
                        parent.onTap(n)
                        return
                    }
                    node = node?.parent
                }
            }
            parent.onTap(nil)
        }
    }
}

