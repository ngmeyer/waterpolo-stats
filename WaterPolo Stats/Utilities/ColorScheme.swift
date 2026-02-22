import SwiftUI

struct WaterPoloColors {
    static let primary = Color(red: 0.8, green: 0.0, blue: 0.0) // Deep Red
    static let secondary = Color(red: 0.0, green: 0.2, blue: 0.6) // Deep Blue
    static let accent = Color.white
    
    static let success = Color(red: 0.0, green: 0.7, blue: 0.3) // Green
    static let warning = Color(red: 1.0, green: 0.6, blue: 0.0) // Orange
    static let danger = Color(red: 0.9, green: 0.1, blue: 0.1) // Bright Red
    
    static let background = Color(red: 0.98, green: 0.98, blue: 0.98)
    static let surface = Color.white
    static let surfaceVariant = Color(red: 0.95, green: 0.95, blue: 0.95)
    
    static let textPrimary = Color(red: 0.1, green: 0.1, blue: 0.1)
    static let textSecondary = Color(red: 0.5, green: 0.5, blue: 0.5)
    
    static let homeTeam = Color(red: 0.8, green: 0.0, blue: 0.0) // Red
    static let awayTeam = Color(red: 0.0, green: 0.2, blue: 0.6) // Blue
}

extension Color {
    static let waterPoloRed = WaterPoloColors.primary
    static let waterPoloBlue = WaterPoloColors.secondary
}
