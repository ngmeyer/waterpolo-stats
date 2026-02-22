import SwiftUI

// MARK: - Empty State Views

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let buttonTitle: String?
    let buttonAction: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        buttonTitle: String? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Animated icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 44))
                    .foregroundColor(.blue)
                    .symbolRenderingMode(.hierarchical)
            }
            .scaleEffect(1.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.5).repeatForever(autoreverses: true), value: true)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if let buttonTitle = buttonTitle, let buttonAction = buttonAction {
                Button(action: buttonAction) {
                    Text(buttonTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Loading State

struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(radius: 10)
        )
    }
}

// MARK: - Error State

struct ErrorView: View {
    let message: String
    let retryAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let retryAction = retryAction {
                Button(action: retryAction) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .font(.headline)
                }
                .padding(.top, 8)
            }
        }
        .padding(32)
    }
}

// MARK: - Animated Counter

struct AnimatedCounter: View {
    let value: Int
    @State private var displayValue: Int = 0
    
    var body: some View {
        Text("\(displayValue)")
            .font(.system(size: 72, weight: .bold, design: .rounded))
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5)) {
                    displayValue = value
                }
            }
            .onChange(of: value) { _, newValue in
                withAnimation(.easeInOut(duration: 0.3)) {
                    displayValue = newValue
                }
            }
    }
}

// MARK: - Pulsing Circle

struct PulsingCircle: View {
    let color: Color
    @State private var isPulsing = false
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 12, height: 12)
            .scaleEffect(isPulsing ? 1.3 : 1.0)
            .opacity(isPulsing ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}

// MARK: - Slide Transition

extension AnyTransition {
    static var slideFromBottom: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }
    
    static var scaleAndFade: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 0.8).combined(with: .opacity)
        )
    }
}

// MARK: - Shake Animation

struct Shake: GeometryEffect {
    var amount: CGFloat = 10
    var shakesPerUnit = 3
    var animatableData: CGFloat
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX:
            amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)),
            y: 0))
    }
}

// MARK: - View Extensions

extension View {
    func shakeAnimation(trigger: Binding<Bool>, amount: CGFloat = 10) -> some View {
        self.modifier(ShakeEffect(trigger: trigger, amount: amount))
    }
}

struct ShakeEffect: ViewModifier {
    @Binding var trigger: Bool
    let amount: CGFloat
    @State private var shakeCount: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .modifier(Shake(animatableData: shakeCount))
            .onChange(of: trigger) { _, newValue in
                if newValue {
                    withAnimation(.linear(duration: 0.4)) {
                        shakeCount += 1
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        trigger = false
                    }
                }
            }
    }
}
