import AVFoundation
import SwiftUI

/// Generates ambient audio programmatically with AVAudioEngine.
/// 7 Zone-based ambient layers with 1-second crossfades based on the ScaleZone.
final class SoundManager: ObservableObject {
    
    private var engine: AVAudioEngine?
    private var toneNode: AVAudioSourceNode?
    private var isPlaying = false
    
    // 7 Layers Volumes (0: Universe, 1: Galaxy, 2: Solar, 3: Human, 4: Cell, 5: Atom, 6: Quantum)
    private var targetVolumes: [Float] = [0, 0, 0, 1, 0, 0, 0] // Start at Human
    private var currentVolumes: [Float] = [0, 0, 0, 1, 0, 0, 0]
    
    private var phases: [Double] = Array(repeating: 0, count: 7)
    
    // Tick burst
    private var tickPhase: Double = 0
    private var tickAmp: Double = 0
    
    init() {
        do {
            let s = AVAudioSession.sharedInstance()
            try s.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try s.setActive(true)
        } catch {}
    }
    
    func startAmbient() {
        guard !isPlaying else { return }
        engine = AVAudioEngine()
        guard let engine = engine else { return }
        
        let sr = engine.outputNode.outputFormat(forBus: 0).sampleRate
        let fmt = AVAudioFormat(standardFormatWithSampleRate: sr, channels: 1)!
        
        // 1-second crossfade constants
        let fadeRate: Float = Float(1.0 / sr)
        
        toneNode = AVAudioSourceNode { [weak self] _, _, frameCount, abl -> OSStatus in
            guard let self = self else { return noErr }
            let buf = UnsafeMutableAudioBufferListPointer(abl)[0].mData!.assumingMemoryBound(to: Float.self)
            
            for i in 0..<Int(frameCount) {
                // Update 7 volumes towards target
                for v in 0..<7 {
                    if self.currentVolumes[v] < self.targetVolumes[v] {
                        self.currentVolumes[v] = min(self.targetVolumes[v], self.currentVolumes[v] + fadeRate)
                    } else if self.currentVolumes[v] > self.targetVolumes[v] {
                        self.currentVolumes[v] = max(self.targetVolumes[v], self.currentVolumes[v] - fadeRate)
                    }
                }
                
                var mixedSignal: Double = 0
                
                // 0: Universe (Deep hum) ~ 40 Hz
                if self.currentVolumes[0] > 0 {
                    self.phases[0] += 40.0 / sr; if self.phases[0] > 1 { self.phases[0] -= 1 }
                    mixedSignal += sin(self.phases[0] * .pi * 2) * Double(self.currentVolumes[0])
                }
                
                // 1: Galaxy (Airy tone) ~ 110 Hz + noise
                if self.currentVolumes[1] > 0 {
                    self.phases[1] += 110.0 / sr; if self.phases[1] > 1 { self.phases[1] -= 1 }
                    let noise = Double.random(in: -0.2...0.2)
                    mixedSignal += (sin(self.phases[1] * .pi * 2) * 0.8 + noise) * Double(self.currentVolumes[1])
                }
                
                // 2: Solar (Warm resonance) ~ 220 Hz + 440 Hz
                if self.currentVolumes[2] > 0 {
                    self.phases[2] += 220.0 / sr; if self.phases[2] > 1 { self.phases[2] -= 1 }
                    let s = sin(self.phases[2] * .pi * 2) + sin(self.phases[2] * .pi * 4) * 0.5
                    mixedSignal += s * Double(self.currentVolumes[2])
                }
                
                // 3: Human (Neutral quiet) ~ barely audible 150 Hz
                if self.currentVolumes[3] > 0 {
                    self.phases[3] += 150.0 / sr; if self.phases[3] > 1 { self.phases[3] -= 1 }
                    mixedSignal += sin(self.phases[3] * .pi * 2) * 0.3 * Double(self.currentVolumes[3])
                }
                
                // 4: Cell (Soft organic texture) ~ 300 Hz vibrating
                if self.currentVolumes[4] > 0 {
                    self.phases[4] += 300.0 / sr; if self.phases[4] > 1 { self.phases[4] -= 1 }
                    let tremolo = (sin(self.phases[4] * .pi * 2 * 0.05) + 1.0) / 2.0
                    mixedSignal += sin(self.phases[4] * .pi * 2) * tremolo * Double(self.currentVolumes[4])
                }
                
                // 5: Atom (Faint oscillation) ~ 600 Hz ring
                if self.currentVolumes[5] > 0 {
                    self.phases[5] += 600.0 / sr; if self.phases[5] > 1 { self.phases[5] -= 1 }
                    mixedSignal += sin(self.phases[5] * .pi * 2) * Double(self.currentVolumes[5])
                }
                
                // 6: Quantum (High harmonic shimmer) ~ 1200 + 2400 Hz
                if self.currentVolumes[6] > 0 {
                    self.phases[6] += 1200.0 / sr; if self.phases[6] > 1 { self.phases[6] -= 1 }
                    let s = sin(self.phases[6] * .pi * 2) + sin(self.phases[6] * .pi * 4) * 0.5
                    mixedSignal += s * Double(self.currentVolumes[6])
                }
                
                // Mix tick
                if self.tickAmp > 0.001 {
                    self.tickPhase += 660 / sr
                    if self.tickPhase > 1 { self.tickPhase -= 1 }
                    mixedSignal += sin(self.tickPhase * .pi * 2) * self.tickAmp
                    self.tickAmp *= 0.997
                }
                
                buf[i] = Float(mixedSignal * 0.15) // Master out level
            }
            return noErr
        }
        
        guard let tn = toneNode else { return }
        engine.attach(tn)
        engine.connect(tn, to: engine.mainMixerNode, format: fmt)
        
        do { try engine.start(); isPlaying = true } catch {}
    }
    
    func stopAmbient() {
        engine?.stop()
        if let tn = toneNode { engine?.detach(tn) }
        toneNode = nil; engine = nil; isPlaying = false
    }
    
    func updateForExponent(_ e: Double) {
        var t = Array(repeating: Float(0), count: 7)
        if e >= 24 { t[0] = 1 }         // Universe
        else if e >= 15 { t[1] = 1 }    // Galaxy
        else if e >= 4 { t[2] = 1 }     // Solar
        else if e >= -2 { t[3] = 1 }    // Human
        else if e >= -7 { t[4] = 1 }    // Cell
        else if e >= -12 { t[5] = 1 }   // Atom
        else { t[6] = 1 }               // Quantum
        
        targetVolumes = t
    }
    
    func playTick() {
        tickPhase = 0; tickAmp = 0.25
    }
    
    func playLevelTone() {
        tickPhase = 0; tickAmp = 0.4
    }
    
    deinit { stopAmbient() }
}
