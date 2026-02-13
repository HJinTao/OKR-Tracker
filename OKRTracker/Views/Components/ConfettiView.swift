import SwiftUI

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var particles: [Particle] = []
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                
                for particle in particles {
                    let time = now - particle.creationDate
                    guard time < particle.duration else { continue }
                    
                    let x = particle.x + particle.vx * time
                    let y = particle.y + particle.vy * time + 0.5 * 500 * time * time // 简单的重力模拟
                    
                    // 旋转计算
                    let rotation = particle.rotationSpeed * time
                    
                    var contextCopy = context
                    contextCopy.translateBy(x: x, y: y)
                    contextCopy.rotate(by: .degrees(rotation * 360))
                    
                    // 渐隐效果
                    let opacity = 1.0 - (time / particle.duration)
                    contextCopy.opacity = opacity
                    
                    contextCopy.fill(
                        Path(roundedRect: CGRect(x: -5, y: -5, width: 10, height: 10), cornerRadius: 2),
                        with: .color(particle.color)
                    )
                }
            }
        }
        .onAppear {
            createParticles()
        }
        .ignoresSafeArea()
        .allowsHitTesting(false) // 确保不阻挡交互
    }
    
    func createParticles() {
        for _ in 0..<100 {
            let particle = Particle(
                x: Double.random(in: 0...UIScreen.main.bounds.width),
                y: -50, // 从屏幕上方开始
                vx: Double.random(in: -100...100),
                vy: Double.random(in: 100...300),
                color: [Color.red, .blue, .green, .yellow, .purple, .orange].randomElement()!,
                duration: Double.random(in: 2...4),
                creationDate: Date().timeIntervalSinceReferenceDate,
                rotationSpeed: Double.random(in: -2...2)
            )
            particles.append(particle)
        }
    }
}

// MARK: - Particle Model
struct Particle {
    let x: Double
    let y: Double
    let vx: Double
    let vy: Double
    let color: Color
    let duration: Double
    let creationDate: TimeInterval
    let rotationSpeed: Double
}

// MARK: - View Modifier
struct CelebrationModifier: ViewModifier {
    @Binding var trigger: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content
            if trigger {
                ConfettiView()
                    .onAppear {
                        // 动画开始时触发触感反馈
                        HapticManager.shared.notification(type: .success)
                        
                        // 3.5秒后自动关闭动画状态
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                            trigger = false
                        }
                    }
            }
        }
    }
}

extension View {
    func celebration(trigger: Binding<Bool>) -> some View {
        self.modifier(CelebrationModifier(trigger: trigger))
    }
}
