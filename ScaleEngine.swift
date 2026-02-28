import SwiftUI
import Combine

/// ScaleEngine: the brain of the zoom journey.
/// Tracks a continuous exponent and detects threshold crossings.
final class ScaleEngine: ObservableObject {
    
    static let minExponent: Double = -18
    static let maxExponent: Double = 27
    static let totalRange: Double = maxExponent - minExponent
    static let startExponent: Double = 0
    
    @Published var currentExponent: Double = 0
    @Published var currentLevel: ScaleLevel = ScaleLevel.humanLevel
    @Published var isAtBoundary: Bool = false
    
    private var lastLevelId: Int = ScaleLevel.humanLevel.id
    
    // Callbacks
    var onThresholdCrossed: (() -> Void)?
    var onLevelChanged: ((ScaleLevel) -> Void)?
    
    /// Process pinch gesture delta. 
    /// delta > 0 means zooming OUT (expanding), delta < 0 means zooming IN (shrinking)
    func applyZoomDelta(_ delta: Double) {
        let sensitivity: Double = 0.4
        let newExp = (currentExponent + delta * sensitivity).clamped(to: Self.minExponent...Self.maxExponent)
        
        checkHapticThresholds(oldExp: currentExponent, newExp: newExp)
        
        currentExponent = newExp
        
        // Level change
        let nearest = ScaleLevel.nearest(to: newExp)
        if nearest.id != lastLevelId {
            currentLevel = nearest
            lastLevelId = nearest.id
            onLevelChanged?(nearest)
        }
        
        isAtBoundary = newExp <= Self.minExponent + 0.1 || newExp >= Self.maxExponent - 0.1
    }
    
    private func checkHapticThresholds(oldExp: Double, newExp: Double) {
        let thresholds: [Double] = [0, -9, 12]
        for t in thresholds {
            if (oldExp < t && newExp >= t) || (oldExp > t && newExp <= t) {
                onThresholdCrossed?()
            }
        }
    }
    
    var journeyProgress: Double {
        (currentExponent - Self.minExponent) / Self.totalRange
    }
    
    var exponentInt: Int {
        Int(round(currentExponent))
    }
    
    var scaleText: String {
        let e = exponentInt
        if e == 0 { return "1 meter" }
        if e > 0 { return "10\(superscript(e)) m" }
        return "10⁻\(superscript(abs(e))) m"
    }
    
    var currentZone: ScaleZone {
        if currentExponent < -12 { return .quantum }
        if currentExponent < -7 { return .atomic }
        if currentExponent < -2 { return .biological }
        if currentExponent < 4 { return .human }
        if currentExponent < 8 { return .planetary }
        if currentExponent < 15 { return .stellar }
        if currentExponent < 24 { return .galactic }
        return .universe
    }
    
    private func superscript(_ n: Int) -> String {
        let digits: [Character: String] = [
            "0":"⁰","1":"¹","2":"²","3":"³","4":"⁴",
            "5":"⁵","6":"⁶","7":"⁷","8":"⁸","9":"⁹"
        ]
        return String(String(n).compactMap { digits[$0] }.joined())
    }
}

enum ScaleZone: String, CaseIterable {
    case quantum = "Quantum"
    case atomic = "Atomic"
    case biological = "Biological"
    case human = "Human"
    case planetary = "Planetary"
    case stellar = "Stellar"
    case galactic = "Galactic"
    case universe = "Universe"
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
