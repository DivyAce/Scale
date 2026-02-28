import SceneKit

/// Creates stunning procedural 3D objects for each of the 9 Anchor Realms.
struct ScaleObjectFactory {
    
    static func create(for level: ScaleLevel) -> SCNNode {
        let root = SCNNode()
        root.name = "level_\(level.id)"
        
        // Ensure no level starts with objects inside it unless built specifically
        switch level.id {
        case 1: buildObservableUniverse(root)
        case 2: buildGalacticRealm(root)
        case 3: buildStellarRealm(root)
        case 4: buildPlanetaryRealm(root)
        case 5: buildHumanRealm(root)
        case 6: buildBiologicalRealm(root)
        case 7: buildMolecularRealm(root)
        case 8: buildAtomicRealm(root)
        case 9: buildQuantumRealm(root)
        default: break
        }
        
        return root
    }
    
    // MARK: - Material Generators
    
    private static func glow(_ hue: CGFloat, _ sat: CGFloat, _ bri: CGFloat, emission: CGFloat = 0.6) -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = UIColor(hue: hue, saturation: sat, brightness: bri, alpha: 1)
        m.emission.contents = UIColor(hue: hue, saturation: sat * 0.7, brightness: emission, alpha: 1)
        m.lightingModel = .physicallyBased
        m.roughness.contents = 0.2
        m.metalness.contents = 0.8
        m.clearCoat.contents = 1.0
        m.clearCoatRoughness.contents = 0.1
        return m
    }
    
    private static func glass(_ hue: CGFloat, _ sat: CGFloat, _ bri: CGFloat, alpha: CGFloat = 0.15) -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = UIColor(hue: hue, saturation: sat, brightness: bri, alpha: alpha)
        m.emission.contents = UIColor(hue: hue, saturation: sat * 0.5, brightness: 0.2, alpha: 1)
        m.isDoubleSided = true
        m.transparency = alpha
        m.lightingModel = .physicallyBased
        m.roughness.contents = 0.05
        m.metalness.contents = 0.1
        m.clearCoat.contents = 1.0
        m.clearCoatRoughness.contents = 0.05
        return m
    }
    
    private static func emissive(_ hue: CGFloat, _ sat: CGFloat, _ bri: CGFloat) -> SCNMaterial {
        let m = SCNMaterial()
        m.diffuse.contents = UIColor(hue: hue, saturation: sat, brightness: bri, alpha: 1)
        m.emission.contents = UIColor(hue: hue, saturation: sat, brightness: bri, alpha: 1)
        m.lightingModel = .physicallyBased
        m.roughness.contents = 0.5
        m.metalness.contents = 0.0
        return m
    }
    
    private static func makeLine(_ from: SCNVector3, _ to: SCNVector3, _ color: UIColor, radius: CGFloat = 0.012) -> SCNNode {
        let dx = to.x - from.x, dy = to.y - from.y, dz = to.z - from.z
        let dist = sqrt(dx*dx + dy*dy + dz*dz)
        let cyl = SCNCylinder(radius: radius, height: CGFloat(dist))
        let m = SCNMaterial()
        m.diffuse.contents = color
        m.emission.contents = color
        m.lightingModel = .physicallyBased
        m.metalness.contents = 0.5
        m.roughness.contents = 0.2
        cyl.firstMaterial = m
        let n = SCNNode(geometry: cyl)
        n.position = SCNVector3((from.x+to.x)/2, (from.y+to.y)/2, (from.z+to.z)/2)
        n.look(at: to, up: SCNVector3(0,1,0), localFront: SCNVector3(0,1,0))
        return n
    }
    
    // MARK: - 1. Observable Universe
    private static func buildObservableUniverse(_ root: SCNNode) {
        // Subtle volumetric haze & sparse filaments
        for _ in 0..<300 {
            let s = SCNSphere(radius: CGFloat.random(in: 0.05...0.15))
            s.firstMaterial = emissive(0.7, 0.4, CGFloat.random(in: 0.2...0.6)) // faint purple/blue
            let n = SCNNode(geometry: s)
            
            let r = Float.random(in: 1...15)
            let theta = Float.random(in: 0...(.pi * 2))
            let phi = Float.random(in: 0...Float.pi)
            n.position = SCNVector3(r * sin(phi) * cos(theta), r * cos(phi), r * sin(phi) * sin(theta))
            root.addChildNode(n)
        }
        // Faint glow center void
        let haze = SCNSphere(radius: 12.0)
        haze.firstMaterial = glass(0.7, 0.5, 0.8, alpha: 0.02)
        root.addChildNode(SCNNode(geometry: haze))
    }
    
    // MARK: - 2. Galactic Realm
    private static func buildGalacticRealm(_ root: SCNNode) {
        let arms = 5; let ptsPerArm = 200
        for arm in 0..<arms {
            let armOff = Double(arm) * .pi * 2.0 / Double(arms)
            for i in 0..<ptsPerArm {
                let t = Double(i) / Double(ptsPerArm)
                // Logarithmic density: more points near center, but distributed smoothly
                let r = max(0.5, pow(t, 0.8) * 10.0)
                let angle = armOff + t * 4.0 * .pi + Double.random(in: -0.2...0.2)
                
                let x = r * cos(angle)
                let z = r * sin(angle)
                let y = Double.random(in: -0.5...0.5) * (1.0 - t)
                
                let size = CGFloat.random(in: 0.02...0.08)
                let s = SCNSphere(radius: size)
                s.firstMaterial = emissive(CGFloat(0.1 + t * 0.5), 0.6, CGFloat(0.5 + (1.0 - t) * 0.5))
                
                let n = SCNNode(geometry: s)
                n.position = SCNVector3(Float(x), Float(y), Float(z))
                root.addChildNode(n)
            }
        }
        
        // Soft HDR Bloom core
        let core = SCNSphere(radius: 1.5)
        core.firstMaterial = glow(0.15, 0.3, 1.0, emission: 1.0)
        root.addChildNode(SCNNode(geometry: core))
        
        let halo = SCNSphere(radius: 3.5)
        halo.firstMaterial = glass(0.15, 0.3, 1.0, alpha: 0.1)
        root.addChildNode(SCNNode(geometry: halo))
        
        // Slow rotation
        root.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 120)))
    }
    
    // MARK: - 3. Stellar Realm
    private static func buildStellarRealm(_ root: SCNNode) {
        // Sun Core
        let sun = SCNSphere(radius: 2.0)
        sun.segmentCount = 64
        let sunMat = glow(0.12, 0.9, 1.0, emission: 1.5)
        sunMat.roughness.contents = 0.8
        sun.firstMaterial = sunMat
        let sunNode = SCNNode(geometry: sun)
        root.addChildNode(sunNode)
        
        // Solar Corona with additive blending
        for i in 1...2 {
            let corona = SCNSphere(radius: 2.0 + CGFloat(i) * 0.2)
            corona.segmentCount = 48
            let cMat = glass(0.12, 0.8, 1.0, alpha: 0.15 / CGFloat(i))
            cMat.blendMode = .add
            corona.firstMaterial = cMat
            
            let cNode = SCNNode(geometry: corona)
            let pulsate = SCNAction.sequence([
                SCNAction.scale(to: 1.05 + CGFloat(i)*0.02, duration: Double(i) * 2.0 + 1.0),
                SCNAction.scale(to: 0.98, duration: Double(i) * 1.5 + 1.0)
            ])
            pulsate.timingMode = .easeInEaseOut
            cNode.runAction(SCNAction.repeatForever(pulsate))
            root.addChildNode(cNode)
        }
        
        // Simplified orbits
        let orbitRadii: [CGFloat] = [3.5, 5.0, 7.0, 9.5]
        let planetSizes: [CGFloat] = [0.1, 0.18, 0.2, 0.15]
        let planetHues: [CGFloat] = [0.05, 0.1, 0.58, 0.03]
        
        for i in 0..<4 {
            let r = orbitRadii[i]
            let ring = SCNTorus(ringRadius: r, pipeRadius: 0.01)
            ring.firstMaterial = emissive(0, 0, 0.3)
            root.addChildNode(SCNNode(geometry: ring))
            
            let planet = SCNSphere(radius: planetSizes[i])
            planet.firstMaterial = glow(planetHues[i], 0.6, 0.8, emission: 0.2)
            let pNode = SCNNode(geometry: planet)
            pNode.position = SCNVector3(Float(r), 0, 0)
            
            let pivot = SCNNode()
            pivot.addChildNode(pNode)
            let duration = 5.0 + Double(i) * 3.0
            pivot.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: duration)))
            pivot.eulerAngles.y = Float.random(in: 0...(.pi * 2))
            root.addChildNode(pivot)
        }
    }
    
    // MARK: - 4. Planetary Realm
    private static func buildPlanetaryRealm(_ root: SCNNode) {
        // High-poly Earth core
        let earth = SCNSphere(radius: 4.0)
        earth.segmentCount = 128
        let em = SCNMaterial()
        // Deep blue ocean, vibrant continents
        em.diffuse.contents = UIColor(hue: 0.58, saturation: 0.9, brightness: 0.6, alpha: 1)
        em.emission.contents = UIColor(hue: 0.58, saturation: 0.5, brightness: 0.15, alpha: 1)
        em.lightingModel = .physicallyBased
        em.roughness.contents = 0.5
        em.metalness.contents = 0.2
        em.clearCoat.contents = 0.8
        em.clearCoatRoughness.contents = 0.1
        earth.firstMaterial = em
        let en = SCNNode(geometry: earth)
        
        // Procedural Landmasses (stylized patches on the sphere)
        for _ in 0..<45 {
            let patch = SCNSphere(radius: CGFloat.random(in: 0.4...1.8))
            patch.segmentCount = 24
            let pm = SCNMaterial()
            // Earth tones: greens and browns
            let hue = CGFloat.random(in: 0.2...0.35)
            pm.diffuse.contents = UIColor(hue: hue, saturation: 0.6, brightness: 0.5, alpha: 1)
            pm.lightingModel = .physicallyBased
            pm.roughness.contents = 0.9
            pm.metalness.contents = 0.0
            patch.firstMaterial = pm
            
            let pn = SCNNode(geometry: patch)
            let lat = Float.random(in: -1.3...1.3)
            let lon = Float.random(in: 0...(.pi * 2))
            // Embed slightly below surface so only the dome shows
            pn.position = SCNVector3(3.5 * cos(lat) * cos(lon), 3.5 * sin(lat), 3.5 * cos(lat) * sin(lon))
            pn.scale = SCNVector3(1.0, 0.4, 1.0) // flatten them
            pn.look(at: SCNVector3(0,0,0))
            en.addChildNode(pn)
        }
        
        // Cloud Layer (slightly larger sphere, additive blending, transparent patches)
        let clouds = SCNSphere(radius: 4.08)
        clouds.segmentCount = 96
        let cm = SCNMaterial()
        cm.diffuse.contents = UIColor(white: 1.0, alpha: 0.3)
        cm.emission.contents = UIColor(white: 1.0, alpha: 0.1)
        cm.transparent.contents = UIColor(white: 1.0, alpha: 0.5)
        cm.lightingModel = .physicallyBased
        cm.blendMode = .add
        cm.isDoubleSided = true
        clouds.firstMaterial = cm
        let cn = SCNNode(geometry: clouds)
        
        // Populate swirling cloud "storms"
        for _ in 0..<25 {
            let storm = SCNTorus(ringRadius: CGFloat.random(in: 0.5...1.5), pipeRadius: CGFloat.random(in: 0.1...0.3))
            let sm = SCNMaterial()
            sm.diffuse.contents = UIColor(white: 1.0, alpha: 0.4)
            sm.emission.contents = UIColor(white: 1.0, alpha: 0.2)
            sm.blendMode = .add
            storm.firstMaterial = sm
            
            let sn = SCNNode(geometry: storm)
            let lat = Float.random(in: -1.0...1.0)
            let lon = Float.random(in: 0...(.pi * 2))
            sn.position = SCNVector3(4.08 * cos(lat) * cos(lon), 4.08 * sin(lat), 4.08 * cos(lat) * sin(lon))
            sn.look(at: SCNVector3(0,0,0))
            cn.addChildNode(sn)
        }
        
        // Cloud rotation (faster than earth)
        cn.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 20)))
        en.addChildNode(cn)
        
        // Atmosphere Rayleigh scattering glow
        let atmos = SCNSphere(radius: 4.25)
        atmos.segmentCount = 64
        let atmosMat = glass(0.6, 0.6, 1.0, alpha: 0.15)
        atmosMat.blendMode = .add
        atmos.firstMaterial = atmosMat
        root.addChildNode(SCNNode(geometry: atmos))
        
        root.addChildNode(en)
        root.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 45)))
    }
    
    // MARK: - 5. Human Realm
    private static func buildHumanRealm(_ root: SCNNode) {
        // High-end procedural abstract statue (Vitruvian Style)
        let goldMat = SCNMaterial()
        goldMat.diffuse.contents = UIColor(red: 1.0, green: 0.85, blue: 0.5, alpha: 1.0)
        goldMat.emission.contents = UIColor(red: 0.2, green: 0.15, blue: 0.05, alpha: 1.0)
        goldMat.lightingModel = .physicallyBased
        goldMat.metalness.contents = 1.0
        goldMat.roughness.contents = 0.25
        goldMat.clearCoat.contents = 1.0
        
        let figureNode = SCNNode()
        
        // Torso
        let torso = SCNCapsule(capRadius: 0.35, height: 1.8)
        torso.firstMaterial = goldMat
        let tn = SCNNode(geometry: torso)
        tn.position.y = 0.9
        figureNode.addChildNode(tn)
        
        // Head
        let head = SCNSphere(radius: 0.3)
        head.firstMaterial = goldMat
        let hn = SCNNode(geometry: head)
        hn.position.y = 2.1
        figureNode.addChildNode(hn)
        
        // Arms
        let armGeo = SCNCapsule(capRadius: 0.15, height: 1.4)
        armGeo.firstMaterial = goldMat
        
        let lArm = SCNNode(geometry: armGeo)
        lArm.position = SCNVector3(-0.6, 1.2, 0)
        lArm.eulerAngles.z = .pi / 8
        figureNode.addChildNode(lArm)
        
        let rArm = SCNNode(geometry: armGeo)
        rArm.position = SCNVector3(0.6, 1.2, 0)
        rArm.eulerAngles.z = -.pi / 8
        figureNode.addChildNode(rArm)
        
        // Legs
        let legGeo = SCNCapsule(capRadius: 0.18, height: 1.6)
        legGeo.firstMaterial = goldMat
        
        let lLeg = SCNNode(geometry: legGeo)
        lLeg.position = SCNVector3(-0.25, -0.6, 0)
        figureNode.addChildNode(lLeg)
        
        let rLeg = SCNNode(geometry: legGeo)
        rLeg.position = SCNVector3(0.25, -0.6, 0)
        figureNode.addChildNode(rLeg)
        
        // Adjust entire figure up so feet are near y=0
        figureNode.position.y = 1.4
        root.addChildNode(figureNode)
        
        // Vitruvian Rings / Mathematical Aura
        let auraNode = SCNNode()
        for i in 0..<3 {
            let ring = SCNTorus(ringRadius: 2.8 + CGFloat(i) * 0.4, pipeRadius: 0.02)
            let ringMat = SCNMaterial()
            ringMat.diffuse.contents = UIColor.cyan
            ringMat.emission.contents = UIColor.cyan.withAlphaComponent(0.8)
            ringMat.lightingModel = .physicallyBased
            ringMat.blendMode = .add
            ring.firstMaterial = ringMat
            
            let rn = SCNNode(geometry: ring)
            rn.eulerAngles = SCNVector3(Float.random(in: 0 ... .pi), Float.random(in: 0 ... .pi), 0)
            
            let rot = SCNAction.rotateBy(x: .pi*2, y: .pi*1.5, z: 0, duration: Double(15 + i*5))
            rn.runAction(SCNAction.repeatForever(rot))
            auraNode.addChildNode(rn)
        }
        auraNode.position.y = 2.0 // Center rings around chest
        root.addChildNode(auraNode)
        
        // Elegant glass pedestal
        let base = SCNCylinder(radius: 2.5, height: 0.1)
        let baseMat = glass(0.6, 0.4, 1.0, alpha: 0.2)
        base.firstMaterial = baseMat
        let baseNode = SCNNode(geometry: base)
        baseNode.position.y = -0.05
        root.addChildNode(baseNode)
        
        // Slow majestic rotation
        root.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 60)))
    }
    
    // MARK: - 6. Biological Realm
    private static func buildBiologicalRealm(_ root: SCNNode) {
        // Stylized Cell
        let mem = SCNSphere(radius: 4.0)
        mem.segmentCount = 96
        let memMat = glass(0.35, 0.5, 0.8, alpha: 0.15)
        memMat.blendMode = .add
        memMat.clearCoat.contents = 0.5
        memMat.roughness.contents = 0.4
        mem.firstMaterial = memMat
        
        let pulse = SCNAction.sequence([
            SCNAction.scale(to: 1.03, duration: 2.5),
            SCNAction.scale(to: 0.97, duration: 2.5)
        ])
        pulse.timingMode = .easeInEaseOut
        
        let memNode = SCNNode(geometry: mem)
        memNode.runAction(SCNAction.repeatForever(pulse))
        root.addChildNode(memNode)
        
        // Nucleus
        let nuc = SCNSphere(radius: 1.2)
        nuc.firstMaterial = glow(0.08, 0.6, 0.8, emission: 0.5)
        let nn = SCNNode(geometry: nuc)
        root.addChildNode(nn)
        
        // DNA Helix rotating gently in the nucleus
        let helix = SCNNode()
        for t in 0..<12 {
            let angle = Double(t) * .pi / 3.0
            let y = Float(t) * 0.15 - 0.9
            
            let p1 = SCNVector3(Float(cos(angle)*0.5), y, Float(sin(angle)*0.5))
            let p2 = SCNVector3(Float(cos(angle + .pi)*0.5), y, Float(sin(angle + .pi)*0.5))
            
            helix.addChildNode(makeLine(p1, p2, UIColor(hue: 0.45, saturation: 0.6, brightness: 0.9, alpha: 0.8), radius: 0.02))
            
            let s1 = SCNSphere(radius: 0.05); s1.firstMaterial = glow(0.55, 0.7, 0.9, emission: 0.8)
            let n1 = SCNNode(geometry: s1); n1.position = p1; helix.addChildNode(n1)
            
            let s2 = SCNSphere(radius: 0.05); s2.firstMaterial = glow(0.12, 0.7, 0.9, emission: 0.8)
            let n2 = SCNNode(geometry: s2); n2.position = p2; helix.addChildNode(n2)
        }
        helix.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 4.0)))
        nn.addChildNode(helix)
        
        // Organelles
        for _ in 0..<15 {
            let s = SCNCapsule(capRadius: 0.15, height: 0.5)
            s.firstMaterial = glow(0.95, 0.6, 0.8, emission: 0.4)
            let n = SCNNode(geometry: s)
            n.eulerAngles = SCNVector3(Float.random(in: 0 ... .pi), Float.random(in: 0 ... .pi), 0)
            let r = Float.random(in: 1.5...3.5)
            let a = Float.random(in: 0...(.pi * 2))
            let b = Float.random(in: -0.8...0.8)
            n.position = SCNVector3(r * cos(a), b * r, r * sin(a))
            root.addChildNode(n)
        }
    }
    
    // MARK: - 7. Molecular Realm
    private static func buildMolecularRealm(_ root: SCNNode) {
        // Ball and stick abstraction (Complex molecule)
        let center = SCNVector3(0, 0, 0)
        let mainNode = SCNNode(geometry: SCNSphere(radius: 0.5))
        mainNode.geometry?.firstMaterial = glow(0.0, 0.0, 0.4, emission: 0.5)
        root.addChildNode(mainNode)
        
        let nodes = [
            SCNVector3(1.5, 1.0, 0), SCNVector3(-1.5, -1.0, 0.5),
            SCNVector3(0, -1.5, -1.5), SCNVector3(1.0, -0.5, 1.5),
            SCNVector3(-1.0, 1.5, -1.0)
        ]
        
        let hues: [CGFloat] = [0.45, 0.15, 0.8, 0.55, 0.1]
        
        for (i, p) in nodes.enumerated() {
            let n = SCNNode(geometry: SCNSphere(radius: 0.3))
            n.geometry?.firstMaterial = glow(hues[i], 0.7, 1.0, emission: 0.8)
            n.position = p
            root.addChildNode(n)
            
            // Soft neon bonds
            let bond = bakeNeonLine(center, p, hue: hues[i])
            root.addChildNode(bond)
        }
        // Sub-bonds
        root.addChildNode(bakeNeonLine(nodes[0], nodes[3], hue: 0.45))
        root.addChildNode(bakeNeonLine(nodes[1], nodes[2], hue: 0.15))
        
        // Subtle vibration
        let vibrate = SCNAction.customAction(duration: 2.0) { node, _ in
            node.position.y = Float(sin(Date().timeIntervalSince1970 * 4.0)) * 0.05
        }
        root.runAction(SCNAction.repeatForever(vibrate))
    }
    
    private static func bakeNeonLine(_ from: SCNVector3, _ to: SCNVector3, hue: CGFloat) -> SCNNode {
        let line = makeLine(from, to, UIColor(hue: hue, saturation: 0.6, brightness: 1.0, alpha: 0.8), radius: 0.04)
        line.geometry?.firstMaterial?.emission.contents = UIColor(hue: hue, saturation: 0.4, brightness: 1.0, alpha: 1.0)
        return line
    }
    
    // MARK: - 8. Atomic Realm
    private static func buildAtomicRealm(_ root: SCNNode) {
        // Nucleus cluster
        let nucleusNode = SCNNode()
        for i in 0..<14 {
            let isProton = i % 2 == 0
            let p = SCNSphere(radius: 0.4)
            p.firstMaterial = glow(isProton ? 0.08 : 0.6, 0.9, 1.0, emission: isProton ? 0.9 : 0.4)
            
            let n = SCNNode(geometry: p)
            // Cluster positions densely
            let dist = Float.random(in: 0...0.6)
            let theta = Float.random(in: 0...(.pi * 2))
            let phi = Float.random(in: 0...Float.pi)
            n.position = SCNVector3(dist * sin(phi) * cos(theta), dist * cos(phi), dist * sin(phi) * sin(theta))
            nucleusNode.addChildNode(n)
        }
        root.addChildNode(nucleusNode)
        
        // Electron probability cloud
        // Using semi-transparent particle field
        let particleSystem = SCNParticleSystem()
        particleSystem.birthRate = 600
        particleSystem.particleLifeSpan = 0.5
        particleSystem.particleSize = 0.2
        particleSystem.particleColor = UIColor(hue: 0.58, saturation: 0.4, brightness: 1.0, alpha: 0.2)
        particleSystem.emitterShape = SCNSphere(radius: 5.0)
        particleSystem.birthLocation = .volume
        particleSystem.blendMode = .additive
        
        let cloudNode = SCNNode()
        cloudNode.addParticleSystem(particleSystem)
        root.addChildNode(cloudNode)
        
        // Pulsating glow backing
        let glowSphere = SCNSphere(radius: 5.5)
        glowSphere.firstMaterial = glass(0.58, 0.6, 1.0, alpha: 0.05)
        root.addChildNode(SCNNode(geometry: glowSphere))
    }
    
    // MARK: - 9. Quantum Realm
    private static func buildQuantumRealm(_ root: SCNNode) {
        // Abstract energy field, wave interference, shifting gradients
        let waveNode = SCNNode()
        
        for i in 0..<6 {
            let torus = SCNTorus(ringRadius: CGFloat(1.5 + Double(i) * 0.8), pipeRadius: 0.2)
            let hue = CGFloat(i) * 0.15 + 0.6 // purple/pink to blue
            
            let tMat = glass(hue, 0.9, 1.0, alpha: 0.25)
            tMat.blendMode = .add
            tMat.emission.contents = UIColor(hue: hue, saturation: 0.8, brightness: 1.5, alpha: 1.0)
            torus.firstMaterial = tMat
            
            let n = SCNNode(geometry: torus)
            n.eulerAngles = SCNVector3(Float.random(in: 0 ... .pi), Float.random(in: 0 ... .pi), Float.random(in: 0 ... .pi))
            
            let rot = SCNAction.rotateBy(x: .pi*2, y: .pi, z: .pi*0.5, duration: Double.random(in: 6...12))
            n.runAction(SCNAction.repeatForever(rot))
            
            waveNode.addChildNode(n)
        }
        
        // Inner vibrating core
        let core = SCNSphere(radius: 1.0)
        core.firstMaterial = glow(0.83, 0.8, 1.0, emission: 0.9)
        let coreNode = SCNNode(geometry: core)
        
        let vib = SCNAction.sequence([
            SCNAction.scale(to: 1.3, duration: 0.1),
            SCNAction.moveBy(x: 0.1, y: -0.1, z: 0, duration: 0.05),
            SCNAction.scale(to: 0.8, duration: 0.1),
            SCNAction.moveBy(x: -0.1, y: 0.1, z: 0, duration: 0.05)
        ])
        coreNode.runAction(SCNAction.repeatForever(vib))
        waveNode.addChildNode(coreNode)
        
        root.addChildNode(waveNode)
    }
}
