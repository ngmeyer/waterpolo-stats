import SwiftUI
import CoreHaptics

// MARK: - Haptics Manager

class HapticsManager {
    static let shared = HapticsManager()
    
    private var engine: CHHapticEngine?
    
    init() {
        prepareHaptics()
    }
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Error starting haptic engine: \(error)")
        }
    }
    
    // MARK: - Standard Haptics
    
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // MARK: - Game Specific Haptics
    
    func goalScored() {
        // Success pattern: light then medium impact
        impact(style: .light)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.impact(style: .medium)
        }
    }
    
    func exclusionCalled() {
        // Warning pattern
        notification(type: .warning)
    }
    
    func gameStarted() {
        // Success pattern
        notification(type: .success)
    }
    
    func gameEnded() {
        // Success pattern with delay
        notification(type: .success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.notification(type: .success)
        }
    }
    
    func clockTick() {
        // Very light impact for each second
        impact(style: .soft)
    }
    
    func buttonPressed() {
        impact(style: .light)
    }
    
    func errorOccurred() {
        notification(type: .error)
    }
}

// MARK: - View Modifiers

struct HapticButtonModifier: ViewModifier {
    let style: UIImpactFeedbackGenerator.FeedbackStyle
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        HapticsManager.shared.impact(style: style)
                    }
            )
    }
}

struct GoalHapticModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        HapticsManager.shared.goalScored()
                    }
            )
    }
}

extension View {
    func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        modifier(HapticButtonModifier(style: style))
    }
    
    func goalHaptic() -> some View {
        modifier(GoalHapticModifier())
    }
}
