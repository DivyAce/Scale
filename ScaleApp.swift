import SwiftUI

@main
struct ScaleApp: App {
    @StateObject private var scaleEngine = ScaleEngine()
    @StateObject private var hapticManager = HapticManager()
    @StateObject private var soundManager = SoundManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(scaleEngine)
                .environmentObject(hapticManager)
                .environmentObject(soundManager)
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
        }
    }
}
