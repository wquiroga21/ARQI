//
//  Extensions.swift
//  SeniorProject
//
//  Created by William Quiroga on 2/26/25.
//

import Foundation
import SwiftUI

// MARK: - Color Extensions
extension Color {
    // System colors
    static let background = Color(.systemBackground)
    static let text = Color("textColor")
    static let accent = Color("accentColor")
    
    // Generate a random pastel color (useful for AI avatar colors)
    static func randomPastel(saturation: Double = 0.5, brightness: Double = 0.9) -> Color {
        let hue = Double.random(in: 0...1)
        return Color(hue: hue, saturation: saturation, brightness: brightness)
    }
    
    // Initialize color with hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // Story icon color - consistent color for story icons regardless of mode
    static var storyIconColor: Color {
        return Color(hex: "#777777") // Mid-gray that looks good in both light and dark mode
    }
}

// MARK: - Theme Manager
struct AppTheme {
    // Light mode colors
    static let lightBackground = Color(hex: "#F5F1E6") // Warm off-white/beige
    static let lightAccent = Color(hex: "#E8A87C") // Muted pastel orange
    static let lightText = Color(hex: "#333333") // Deep charcoal gray
    static let lightSecondaryText = Color(hex: "#7D7D7D") // Soft gray
    static let lightButton = Color(hex: "#F4A261") // Stronger orange for buttons
    static let lightBorder = Color(hex: "#DAD2BC") // Desaturated beige
    static let lightIcon = Color(hex: "#5E5E5E") // Balanced gray
    static let lightCard = Color.white.opacity(0.9)
    
    // Dark mode colors - Updated to match the layered black approach
    static let darkBackground = Color(hex: "#121212") // Very dark, almost black background
    static let darkAccent = Color(hex: "#E8A87C") // Same orange accent
    static let darkText = Color(hex: "#E8E8E8") // Light gray
    static let darkSecondaryText = Color(hex: "#ADADAD") // Medium gray
    static let darkButton = Color(hex: "#F4A261").opacity(0.9) // Slightly toned down
    static let darkBorder = Color(hex: "#2C2C2C") // Subtle dark border
    static let darkIcon = Color(hex: "#B8B8B8") // Light gray
    static let darkCard = Color(hex: "#1E1E1E") // Slightly lighter than background for cards
    static let darkSecondaryCard = Color(hex: "#282828") // Even lighter for foreground elements
}

// MARK: - AppColor that works with Dark Mode
struct AppColor {
    static func dynamicColor(light: String, dark: String) -> Color {
        return Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ?
                UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

// Extension to UIColor for hex initialization
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

// MARK: - Theme Colors Extension for backward compatibility
extension Color {
    // These extensions allow existing code to continue working while adapting to dark/light mode
    static var appBackground: Self {
        AppColor.dynamicColor(light: "#F5F1E6", dark: "#121212")
    }
    
    static var primaryAccent: Self {
        AppColor.dynamicColor(light: "#E8A87C", dark: "#E8A87C")
    }
    
    static var primaryText: Self {
        AppColor.dynamicColor(light: "#333333", dark: "#E8E8E8")
    }
    
    static var secondaryText: Self {
        AppColor.dynamicColor(light: "#7D7D7D", dark: "#ADADAD")
    }
    
    static var buttonColor: Self {
        AppColor.dynamicColor(light: "#F4A261", dark: "#F4A261")
    }
    
    static var borderColor: Self {
        AppColor.dynamicColor(light: "#DAD2BC", dark: "#2C2C2C")
    }
    
    static var iconColor: Self {
        AppColor.dynamicColor(light: "#5E5E5E", dark: "#B8B8B8")
    }
    
    static var cardBackground: Self {
        AppColor.dynamicColor(light: "#FFFFFF", dark: "#1E1E1E")
    }
    
    // Adding a new color for secondary cards/elements in dark mode
    static var secondaryCardBackground: Self {
        AppColor.dynamicColor(light: "#F9F9F9", dark: "#282828")
    }
}

// MARK: - Date Extensions
extension Date {
    // Renamed to avoid conflicts
    func getTimeAgo() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    // Renamed to avoid conflicts
    func formatDate(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return formatter.string(from: self)
    }
}

// MARK: - String Extensions
extension String {
    func trimmed() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var isNotEmpty: Bool {
        return !self.isEmpty
    }
    
    // Check if the string is a valid email
    var isValidEmail: Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: self)
    }
}

// MARK: - View Extensions
extension View {
    // Add a custom corner radius to specific corners
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    // Add a shadow with custom settings
    func customShadow(color: Color = Color.black.opacity(0.1), radius: CGFloat = 10, x: CGFloat = 0, y: CGFloat = 4) -> some View {
        self.shadow(color: color, radius: radius, x: x, y: y)
    }
    
    // Create a card-style view
    func cardStyle(backgroundColor: Color = Color.cardBackground, cornerRadius: CGFloat = 12) -> some View {
        self
            .padding()
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .customShadow()
    }
    
    // Add consistent padding across the app
    func standardPadding() -> some View {
        self.padding(.horizontal, 16).padding(.vertical, 12)
    }
}

// Helper shape for custom corner radius
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
