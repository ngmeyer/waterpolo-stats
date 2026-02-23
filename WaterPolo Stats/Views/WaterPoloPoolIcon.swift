import SwiftUI

// MARK: - Water Polo Pool Icon
// For use as app icon - overhead view of pool with goals

struct WaterPoloPoolIcon: View {
    var size: CGFloat = 1024
    
    var body: some View {
        ZStack {
            // Pool background
            RoundedRectangle(cornerRadius: size * 0.08)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.0, green: 0.6, blue: 0.9),
                            Color(red: 0.0, green: 0.4, blue: 0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // Pool border/edge
            RoundedRectangle(cornerRadius: size * 0.08)
                .stroke(Color.white.opacity(0.3), lineWidth: size * 0.02)
            
            // 2M lines (exclusion zones)
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: size * 0.15)
                
                Spacer()
                
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: size * 0.15)
            }
            .padding(.horizontal, size * 0.05)
            
            // 5M lines (penalty zones)
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: size * 0.05)
                    .padding(.leading, size * 0.2)
                
                Spacer()
                
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: size * 0.05)
                    .padding(.trailing, size * 0.2)
            }
            
            // Goals (red floats)
            HStack {
                // Left goal
                VStack(spacing: size * 0.02) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: size * 0.06, height: size * 0.06)
                    Circle()
                        .fill(Color.red)
                        .frame(width: size * 0.06, height: size * 0.06)
                    Circle()
                        .fill(Color.red)
                        .frame(width: size * 0.06, height: size * 0.06)
                }
                .padding(.leading, size * 0.03)
                
                Spacer()
                
                // Right goal
                VStack(spacing: size * 0.02) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: size * 0.06, height: size * 0.06)
                    Circle()
                        .fill(Color.red)
                        .frame(width: size * 0.06, height: size * 0.06)
                    Circle()
                        .fill(Color.red)
                        .frame(width: size * 0.06, height: size * 0.06)
                }
                .padding(.trailing, size * 0.03)
            }
            
            // Half-distance line (center)
            Rectangle()
                .fill(Color.white.opacity(0.3))
                .frame(width: size * 0.01)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview for Export

struct WaterPoloPoolIcon_Previews: PreviewProvider {
    static var previews: some View {
        // iOS App Icon sizes
        VStack(spacing: 20) {
            WaterPoloPoolIcon(size: 1024)
                .frame(width: 200, height: 200)
                .previewDisplayName("1024pt (App Store)")
            
            WaterPoloPoolIcon(size: 180)
                .frame(width: 100, height: 100)
                .previewDisplayName("180pt (iPhone)")
            
            WaterPoloPoolIcon(size: 120)
                .frame(width: 60, height: 60)
                .previewDisplayName("120pt (iPhone)")
            
            WaterPoloPoolIcon(size: 60)
                .frame(width: 30, height: 30)
                .previewDisplayName("60pt (iPhone)")
        }
    }
}
