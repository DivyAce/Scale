import SwiftUI
import Combine

/// Defines the 9 Major Anchor Realms in the scale journey.
struct ScaleLevel: Identifiable, Equatable {
    let id: Int
    let exponent: Double
    let name: String
    let emoji: String
    
    // 4 Information Layers
    let fact: String
    let measurement: String
    let concept: String
    let reflection: String
    
    let colorHue: Double
    let colorSat: Double
    let colorBright: Double
    
    var color: Color {
        Color(hue: colorHue, saturation: colorSat, brightness: colorBright)
    }
    
    static func == (lhs: ScaleLevel, rhs: ScaleLevel) -> Bool { lhs.id == rhs.id }
}

extension ScaleLevel {
    static let allLevels: [ScaleLevel] = [
        ScaleLevel(id: 1, exponent: 27, name: "Observable Universe", emoji: "🌌",
                   fact: "The edge of everything we can see.",
                   measurement: "10²⁷ m",
                   concept: "Beyond this boundary, light hasn't had time to reach us since the Big Bang, 13.8 billion years ago. The universe continues infinitely, but our vision is bounded by time.",
                   reflection: "We are looking into the past, at the very beginning of time.",
                   colorHue: 0.0, colorSat: 0.0, colorBright: 1.0),
        
        ScaleLevel(id: 2, exponent: 21, name: "Galactic Realm", emoji: "🌠",
                   fact: "Our galaxy contains 200 billion stars.",
                   measurement: "10²¹ m",
                   concept: "The Milky Way rotates at 828,000 km/h. It takes our solar system 230 million years to complete one orbit. Our Sun is just an ordinary star in a quiet suburban spiral arm.",
                   reflection: "A single grain of sand on a vast cosmic beach.",
                   colorHue: 0.65, colorSat: 0.7, colorBright: 0.8),
                   
        ScaleLevel(id: 3, exponent: 11, name: "Stellar Realm", emoji: "☀️",
                   fact: "The Sun is 99.8% of our solar system's mass.",
                   measurement: "10¹¹ m",
                   concept: "Every 1.5 seconds, the Sun converts 6 million tons of matter into pure energy. This light energy travels for 8 minutes to warm the Earth.",
                   reflection: "The engine of life, burning patiently in the dark.",
                   colorHue: 0.12, colorSat: 0.9, colorBright: 1.0),
                   
        ScaleLevel(id: 4, exponent: 6, name: "Planetary Realm", emoji: "🌍",
                   fact: "Earth is the only known home for life.",
                   measurement: "10⁶ m",
                   concept: "Our atmosphere is a fragile, paper-thin layer insulating our planet from the cold vacuum of space. The conditions for life are incredibly rare.",
                   reflection: "A pale blue dot suspended in a sunbeam.",
                   colorHue: 0.58, colorSat: 0.8, colorBright: 0.85),
                   
        ScaleLevel(id: 5, exponent: 0, name: "Human Realm", emoji: "👤",
                   fact: "You exist at the exact center of the observable scale range.",
                   measurement: "10⁰ m",
                   concept: "You are as many orders of magnitude from a quark as you are from the observable universe. You are the universe experiencing itself.",
                   reflection: "The observer between infinities.",
                   colorHue: 0.0, colorSat: 0.0, colorBright: 1.0),
                   
        ScaleLevel(id: 6, exponent: -5, name: "Biological Realm", emoji: "🔬",
                   fact: "You are made of 37 trillion living cells.",
                   measurement: "10⁻⁵ m",
                   concept: "Inside each cell, thousands of microscopic machines transcribe information, build proteins, and generate energy. It is a bustling, microscopic city.",
                   reflection: "A universe of complexity within a single drop of water.",
                   colorHue: 0.35, colorSat: 0.5, colorBright: 0.8),
                   
        ScaleLevel(id: 7, exponent: -9, name: "Molecular Realm", emoji: "🧬",
                   fact: "The language of life is written in DNA.",
                   measurement: "10⁻⁹ m",
                   concept: "Atoms begin to bond into complex structures. The precise arrangement of these molecules determines whether they become a rock, a leaf, or a human.",
                   reflection: "The fundamental alphabet of existence.",
                   colorHue: 0.45, colorSat: 0.6, colorBright: 0.85),
                   
        ScaleLevel(id: 8, exponent: -10, name: "Atomic Realm", emoji: "⚛️",
                   fact: "Atoms are 99.999% empty space.",
                   measurement: "10⁻¹⁰ m",
                   concept: "Solid matter is an illusion created by electromagnetic fields. The electrons orbiting a nucleus do not move like planets, but exist in clouds of probability.",
                   reflection: "Solid walls are mostly nothing at all.",
                   colorHue: 0.58, colorSat: 0.7, colorBright: 0.9),
                   
        ScaleLevel(id: 9, exponent: -18, name: "Quantum Realm", emoji: "✨",
                   fact: "The fundamental fabric of reality.",
                   measurement: "10⁻¹⁸ m",
                   concept: "At this scale, normal physics breaks down. Particles can exist in multiple places at once, and empty space boils with virtual particles popping in and out of existence.",
                   reflection: "The blurry, unstable foundation of the cosmos.",
                   colorHue: 0.83, colorSat: 0.8, colorBright: 1.0)
    ]
    
    static let humanLevel = allLevels.first(where: { $0.exponent == 0 })!
    
    static func nearest(to exponent: Double) -> ScaleLevel {
        allLevels.min(by: { abs($0.exponent - exponent) < abs($1.exponent - exponent) })!
    }
}
