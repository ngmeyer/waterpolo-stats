import SwiftUI
import UIKit

// MARK: - Sunlight Mode Environment

struct SunlightModeKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isSunlightMode: Bool {
        get { self[SunlightModeKey.self] }
        set { self[SunlightModeKey.self] = newValue }
    }
}

// MARK: - Sunlight Mode Modifier

struct SunlightModeModifier: ViewModifier {
    @Binding var isEnabled: Bool
    @State private var isBrightEnvironment: Bool = false
    
    func body(content: Content) -> some View {
        content
            .environment(\.isSunlightMode, isEnabled || isBrightEnvironment)
            .onAppear {
                checkBrightness()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIScreen.brightnessDidChangeNotification)) { _ in
                checkBrightness()
            }
    }
    
    private func checkBrightness() {
        let brightness = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.brightness ?? 0.5
        isBrightEnvironment = brightness > 0.8
    }
}

extension View {
    func sunlightMode(isEnabled: Binding<Bool>) -> some View {
        modifier(SunlightModeModifier(isEnabled: isEnabled))
    }
}

// MARK: - Sunlight Adaptive View

struct SunlightAdaptive<Content: View>: View {
    @Environment(\.isSunlightMode) var isSunlightMode
    let sunlight: () -> Content
    let normal: () -> Content
    
    init(@ViewBuilder sunlight: @escaping () -> Content, @ViewBuilder normal: @escaping () -> Content) {
        self.sunlight = sunlight
        self.normal = normal
    }
    
    var body: some View {
        if isSunlightMode {
            sunlight()
        } else {
            normal()
        }
    }
}
