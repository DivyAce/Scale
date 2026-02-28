import SwiftUI

/// Root view: intro → experience, with engine/haptic/sound wiring.
struct ContentView: View {
    @EnvironmentObject var scaleEngine: ScaleEngine
    @EnvironmentObject var hapticManager: HapticManager
    @EnvironmentObject var soundManager: SoundManager
    @State private var showIntro = true
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if showIntro {
                IntroView {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        showIntro = false
                    }
                    soundManager.startAmbient()
                }
                .transition(.opacity)
            } else {
                ExperienceView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            scaleEngine.onThresholdCrossed = {
                // Only fires at 10^0, 10^-9, 10^12 based on new ScaleEngine
                hapticManager.playThresholdTick()
            }
            scaleEngine.onLevelChanged = { level in
                // Crossfade is handled automatically by SoundManager based on currentExponent
            }
        }
    }
}
