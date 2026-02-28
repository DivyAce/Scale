import SceneKit
import SwiftUI

/// The 3D universe scene with smooth zoom transitions and explorable levels.
class UniverseScene: SCNScene, ObservableObject {
    
    let cameraNode = SCNNode()
    private let pivotNode = SCNNode() // parent for camera, enables orbit
    private var levelNodes: [Int: SCNNode] = [:]
    private var currentExponent: Double = 0
    private var rotationAngles: [Int: Float] = [:]
    
    override init() {
        super.init()
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }
    
    private func setup() {
        background.contents = UIColor.black
        
        // Camera on a pivot for orbit control
        let camera = SCNCamera()
        camera.zNear = 0.001
        camera.zFar = 1000
        camera.fieldOfView = 55
        camera.wantsHDR = true
        camera.bloomIntensity = 0.8
        camera.bloomThreshold = 0.5
        camera.bloomBlurRadius = 10
        camera.wantsExposureAdaptation = false
        camera.motionBlurIntensity = 0
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 10) // Fixed camera distance
        pivotNode.addChildNode(cameraNode)
        rootNode.addChildNode(pivotNode)
        
        // Ambient light
        let amb = SCNNode()
        let al = SCNLight(); al.type = .ambient
        al.intensity = 500; al.color = UIColor(white: 0.35, alpha: 1)
        amb.light = al; amb.name = "ambient"
        rootNode.addChildNode(amb)
        
        // Build all level nodes
        for level in ScaleLevel.allLevels {
            let node = ScaleObjectFactory.create(for: level)
            node.opacity = 0
            node.isHidden = true
            node.name = "level_\(level.id)"
            rootNode.addChildNode(node)
            levelNodes[level.id] = node
            rotationAngles[level.id] = 0
        }
        
        // Background stars
        addDeepStarField()
        
        // Start a render loop for animations
        startAnimationTimer()
    }
    
    // MARK: - Deep Star Field
    
    private func addDeepStarField() {
        let node = SCNNode(); node.name = "deepstars"
        for layer in 0..<3 {
            let count = [300, 150, 60][layer]
            let rMin: Float = [50, 150, 300][layer]
            let rMax: Float = [149, 299, 600][layer]
            let sizeMin: CGFloat = [0.02, 0.04, 0.08][layer]
            let sizeMax: CGFloat = [0.06, 0.1, 0.2][layer]
            
            for _ in 0..<count {
                let s = SCNSphere(radius: CGFloat.random(in: sizeMin...sizeMax))
                let brightness = CGFloat.random(in: 0.2...1.0)
                let hue = CGFloat.random(in: 0.0...0.15)
                let mat = SCNMaterial()
                mat.diffuse.contents = UIColor(hue: hue, saturation: 0.15, brightness: brightness, alpha: 1)
                mat.emission.contents = UIColor(hue: hue, saturation: 0.1, brightness: brightness * 0.9, alpha: 1)
                mat.lightingModel = .constant
                s.firstMaterial = mat
                let n = SCNNode(geometry: s)
                let r = Float.random(in: rMin...rMax)
                let theta = Float.random(in: 0...(.pi * 2))
                let phi = Float.random(in: 0...Float.pi)
                n.position = SCNVector3(r * sin(phi) * cos(theta), r * cos(phi), r * sin(phi) * sin(theta))
                node.addChildNode(n)
            }
        }
        rootNode.addChildNode(node)
    }
    
    // MARK: - Animation Timer
    
    private func startAnimationTimer() {
        let rotateAction = SCNAction.customAction(duration: 1000000) { [weak self] _, elapsed in
            guard let self = self else { return }
            for (id, node) in self.levelNodes where !node.isHidden {
                let speed: Float = 0.0008
                self.rotationAngles[id, default: 0] += speed
                node.eulerAngles.y = self.rotationAngles[id, default: 0]
            }
        }
        rootNode.runAction(rotateAction, forKey: "globalRotate")
    }
    
    // MARK: - Zoom Update
    
    func updateZoom(exponent: Double) {
        currentExponent = exponent
        
        // Update object visibility with log-crossfade system
        updateVisibility(exponent)
        
        // Update ambient mood
        updateMood(exponent)
    }
    
    // MARK: - Camera Control
    
    func rotateCamera(dx: Float, dy: Float) {
        pivotNode.eulerAngles.y -= dx * 0.005
        pivotNode.eulerAngles.x -= dy * 0.005
        pivotNode.eulerAngles.x = max(-.pi / 2, min(.pi / 2, pivotNode.eulerAngles.x))
    }
    
    func resetCamera() {
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        pivotNode.eulerAngles = SCNVector3Zero
        SCNTransaction.commit()
    }
    
    // MARK: - Visibility & Logarithmic Crossfade
    
    private func updateVisibility(_ exponent: Double) {
        // We do NOT use SCNTransaction animations for scale or opacity here, 
        // to ensure zero-lag 60fps immediate responsiveness to the pinch gesture.
        
        // Severely restricting visibility range to drop unnecessary nodes
        let visRange: Double = 0.65 // Fade across 0.65 log units
        
        for level in ScaleLevel.allLevels {
            guard let node = levelNodes[level.id] else { continue }
            
            let logDist = exponent - level.exponent
            let absDist = abs(logDist)
            
            if absDist < visRange {
                if node.isHidden { node.isHidden = false }
                
                // Opacity is controlled by proximity to log-scale center
                // 1.0 at center, fading down to 0 at visRange
                let t = 1.0 - (absDist / visRange)
                let smoothOpacity = smoothstep(t)
                node.opacity = CGFloat(smoothOpacity)
                
                // Scale driven precisely by log distance
                // We restrict extreme scaling. SceneKit's BVH struggles with anything outside 0.01 - 100.0
                let physicalScale = pow(10.0, -logDist)
                let s = max(0.1, min(10.0, Float(physicalScale))) // Heavily clamped
                node.scale = SCNVector3(s, s, s)
                
            } else {
                if !node.isHidden {
                    node.isHidden = true
                    node.opacity = 0
                }
            }
        }
    }
    
    // MARK: - Mood Lighting
    
    private func updateMood(_ e: Double) {
        let hue: CGFloat
        let sat: CGFloat
        let bri: CGFloat
        
        if e < -12 {
            hue = 0.78; sat = 0.35; bri = 0.3 // quantum / quark
        } else if e < -4 {
            hue = 0.42; sat = 0.25; bri = 0.32 // bio / atomic
        } else if e < 4 {
            hue = 0.1; sat = 0.08; bri = 0.38 // human / neutral
        } else if e < 15 {
            hue = 0.58; sat = 0.35; bri = 0.32 // solar / planetary
        } else {
            hue = 0.65; sat = 0.4; bri = 0.28 // galactic / universe
        }
        
        if let ambNode = rootNode.childNode(withName: "ambient", recursively: false) {
            // Safe to animate color since it's just lighting
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.3
            ambNode.light?.color = UIColor(hue: hue, saturation: sat, brightness: bri, alpha: 1)
            SCNTransaction.commit()
        }
    }
    
    private func smoothstep(_ t: Double) -> Double {
        let x = max(0, min(1, t))
        return x * x * (3 - 2 * x)
    }
}
