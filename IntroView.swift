import SwiftUI

/// Cinematic intro with three phases of text.
struct IntroView: View {
    let onComplete: () -> Void
    @EnvironmentObject var hapticManager: HapticManager
    
    @State private var phase = 0
    @State private var opacity: Double = 0
    @State private var scale: Double = 0.92
    @State private var subOpacity: Double = 0
    
    private let phases: [(String, String)] = [
        ("You are here.", "Standing at one meter."),
        ("But the universe doesn't end\nat your fingertips.", "It stretches across 45 orders of magnitude."),
        ("Pinch.\nAnd discover.", "Experience the size of reality.")
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Subtle star dots
            Canvas { ctx, size in
                for i in 0..<40 {
                    let x = CGFloat(((i * 7 + 3) * 137) % Int(size.width))
                    let y = CGFloat(((i * 11 + 7) * 97) % Int(size.height))
                    let r = CGFloat.random(in: 0.5...1.5)
                    let o = Double(phase >= 1 ? 1 : 0) * Double.random(in: 0.1...0.3)
                    ctx.opacity = o
                    ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r*2, height: r*2)), with: .color(.white))
                }
            }
            .animation(.easeIn(duration: 2), value: phase)
            
            VStack(spacing: 18) {
                if phase < phases.count {
                    Text(phases[phase].0)
                        .font(.system(size: 30, weight: .thin))
                        .tracking(2)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .opacity(opacity)
                        .scaleEffect(scale)
                    
                    Text(phases[phase].1)
                        .font(.system(size: 15, weight: .ultraLight))
                        .tracking(1.5)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.4))
                        .opacity(subOpacity)
                }
            }
            .padding(36)
            
            VStack {
                Spacer()
                Text(phase < phases.count - 1 ? "tap to continue" : "tap to begin")
                    .font(.system(size: 12, weight: phase < phases.count - 1 ? .ultraLight : .light))
                    .tracking(3)
                    .foregroundColor(phase < phases.count - 1 ? .white.opacity(0.2) : .cyan.opacity(0.4))
                    .padding(.bottom, 50)
                    .opacity(opacity)
            }
        }
        .onTapGesture { advance() }
        .onAppear {
            hapticManager.playIntroSequence()
            animateIn()
        }
    }
    
    private func animateIn() {
        opacity = 0; scale = 0.92; subOpacity = 0
        withAnimation(.easeOut(duration: 1.0)) { opacity = 1; scale = 1.0 }
        withAnimation(.easeOut(duration: 1.0).delay(0.4)) { subOpacity = 1 }
    }
    
    private func advance() {
        hapticManager.playTap()
        if phase >= phases.count - 1 {
            withAnimation(.easeOut(duration: 0.6)) { opacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { onComplete() }
        } else {
            withAnimation(.easeIn(duration: 0.4)) { opacity = 0; subOpacity = 0; scale = 1.03 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { phase += 1; animateIn() }
        }
    }
}
