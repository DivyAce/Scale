import SwiftUI

/// Represents a specific, tappable sub-element within a scale level.
struct ScaleElement: Identifiable, Equatable {
    let id: String // Maps to SCNNode.name
    let title: String
    let subtitle: String
    let description: String
    
    static let allElements: [String: ScaleElement] = [
        // Solar System
        "element_sun": ScaleElement(id: "element_sun", title: "The Sun", subtitle: "G-Type Main-Sequence Star", description: "Contains 99.86% of the mass in the Solar System. Its core reaches 15 million °C, fusing 600 million tons of hydrogen every second."),
        "element_mercury": ScaleElement(id: "element_mercury", title: "Mercury", subtitle: "The Swift Planet", description: "The smallest and innermost planet. It has no atmosphere to retain heat, causing surface temperatures to swing from 430°C to -180°C."),
        "element_venus": ScaleElement(id: "element_venus", title: "Venus", subtitle: "Earth's Toxic Twin", description: "Wrapped in a thick, toxic atmosphere of carbon dioxide that traps heat, creating a runaway greenhouse effect. The hottest planet in our system."),
        "element_earth": ScaleElement(id: "element_earth", title: "Earth", subtitle: "The Pale Blue Dot", description: "The only astronomical object known to harbor life. 71% of its surface is covered by liquid water oceans."),
        "element_mars": ScaleElement(id: "element_mars", title: "Mars", subtitle: "The Red Planet", description: "Its red color comes from iron oxide (rust) on its surface. It hosts Olympus Mons, the largest volcano in the solar system."),
        "element_jupiter": ScaleElement(id: "element_jupiter", title: "Jupiter", subtitle: "The Gas Giant", description: "The largest planet in the solar system. Its iconic Great Red Spot is a giant storm that has been raging for hundreds of years."),
        "element_saturn": ScaleElement(id: "element_saturn", title: "Saturn", subtitle: "The Ringed Planet", description: "Famous for its extensive ring system, mostly made of ice particles, rocky debris, and dust. It is the least dense planet—it would float in water."),
        "element_uranus": ScaleElement(id: "element_uranus", title: "Uranus", subtitle: "The Ice Giant", description: "Rotates on its side, likely due to a massive collision in the past. It has a faint ring system and an icy mantle."),
        "element_neptune": ScaleElement(id: "element_neptune", title: "Neptune", subtitle: "The Windiest Planet", description: "Dark, cold, and whipped by supersonic winds up to 2,100 km/h. It was the first planet located through mathematical calculations."),
        
        // Sun
        "element_flare": ScaleElement(id: "element_flare", title: "Solar Flare", subtitle: "Magnetic Eruption", description: "A sudden flash of increased brightness on the Sun, usually observed near its surface and in close proximity to a sunspot group. Powerful flares can disrupt communications on Earth."),
        "element_corona": ScaleElement(id: "element_corona", title: "Solar Corona", subtitle: "The Outer Atmosphere", description: "An aura of plasma that surrounds the Sun. Ironically, it is millions of degrees hotter than the Sun's actual surface."),
        
        // Milky Way
        "element_galactic_core": ScaleElement(id: "element_galactic_core", title: "Galactic Core", subtitle: "Sagittarius A*", description: "The rotational center of the Milky Way, housing a supermassive black hole with the mass of 4.3 million Suns."),
        "element_spiral_arm": ScaleElement(id: "element_spiral_arm", title: "Spiral Arm", subtitle: "Orion Spur", description: "Regions of stars, gas, and dust that extend from the galactic center. Our solar system is located in the minor Orion Arm."),
        
        // Nebula
        "element_stellar_nursery": ScaleElement(id: "element_stellar_nursery", title: "Stellar Nursery", subtitle: "Star Formation Region", description: "Dense clouds of gas and dust collapsing under their own gravity to form new stars. The intense radiation from young stars illuminates the surrounding gas."),
        "element_protostar": ScaleElement(id: "element_protostar", title: "Protostar", subtitle: "A Star is Born", description: "A very young star that is still gathering mass from its parent molecular cloud. Fusion has not yet begun in its core."),
        
        // Galaxy Cluster
        "element_local_group": ScaleElement(id: "element_local_group", title: "Local Group Galaxy", subtitle: "Gravitationally Bound", description: "One of over 80 galaxies bound together by gravity. The largest are Andromeda, the Milky Way, and the Triangulum Galaxy."),
        "element_dark_matter": ScaleElement(id: "element_dark_matter", title: "Dark Matter Filament", subtitle: "The Cosmic Scaffold", description: "Invisible matter that makes up 85% of the universe's mass. Its gravity binds galaxies together into massive clusters and long filaments."),
        
        // Universe
        "element_supercluster": ScaleElement(id: "element_supercluster", title: "Supercluster Node", subtitle: "Laniakea", description: "A massive concentration of thousands of galaxies. The Milky Way sits on the outskirts of the Laniakea Supercluster, which spans 520 million light-years."),
        "element_void": ScaleElement(id: "element_void", title: "Cosmic Void", subtitle: "Empty Space", description: "Vast spaces between filaments, containing very few, or no, galaxies. The Boötes void is nearly 330 million light-years in diameter.")
    ]
}
