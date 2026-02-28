import CoreHaptics
import SwiftUI

/// CoreHaptics manager with rich tactile feedback patterns.
final class HapticManager: ObservableObject {
    
    private var engine: CHHapticEngine?
    private var running = false
    
    init() { prepare() }
    
    private func prepare() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            engine?.isAutoShutdownEnabled = true
            engine?.resetHandler = { [weak self] in self?.restart() }
            engine?.stoppedHandler = { [weak self] _ in self?.running = false }
            try engine?.start(); running = true
        } catch {}
    }
    
    private func restart() {
        do { try engine?.start(); running = true } catch {}
    }
    
    private func play(_ events: [CHHapticEvent]) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        if !running { restart() }
        do {
            let p = try CHHapticPattern(events: events, parameters: [])
            try engine?.makePlayer(with: p).start(atTime: CHHapticTimeImmediate)
        } catch {}
    }
    
    /// Crisp tick at power-of-10 boundary
    func playThresholdTick() {
        play([CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.85),
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.65)
        ], relativeTime: 0)])
    }
    
    /// Heavier impact when entering a named scale level
    func playLevelTransition() {
        play([
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ], relativeTime: 0),
            CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
            ], relativeTime: 0.06, duration: 0.2)
        ])
    }
    
    /// Rising intro pulse
    func playIntroSequence() {
        var events: [CHHapticEvent] = []
        for i in 0..<6 {
            let t = Double(i) * 0.25
            let intensity = Float(i + 1) / 6.0
            events.append(CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3 + intensity * 0.4)
            ], relativeTime: t))
        }
        play(events)
    }
    
    /// Soft tap for UI
    func playTap() {
        play([CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.35),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.65)
        ], relativeTime: 0)])
    }
    
    /// Double-tap boundary warning
    func playBoundary() {
        play([
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
            ], relativeTime: 0),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
            ], relativeTime: 0.1)
        ])
    }
    
    deinit { engine?.stop() }
}
