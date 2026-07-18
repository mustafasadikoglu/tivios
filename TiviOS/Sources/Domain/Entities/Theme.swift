import Foundation

public enum ThemeType: String, Codable, CaseIterable {
    case darkPurple = "Ametist Gece"
    case oledBlack = "OLED Siyah"
    case cyberpunk = "Cyberpunk Neon"
}

public struct Theme: Equatable {
    public let type: ThemeType
    public let primaryGradient: [String]
    public let backgroundGradient: [String]
    public let cardBackground: String
    public let accentColor: String
    public let textColor: String
    
    public static func getTheme(for type: ThemeType) -> Theme {
        switch type {
        case .darkPurple:
            return Theme(
                type: .darkPurple,
                primaryGradient: ["FF007A", "7928CA"],
                backgroundGradient: ["0F0C20", "15102A", "06040A"],
                cardBackground: "FFFFFF", // with opacity
                accentColor: "FF007A",
                textColor: "FFFFFF"
            )
        case .oledBlack:
            return Theme(
                type: .oledBlack,
                primaryGradient: ["00F0FF", "0072FF"],
                backgroundGradient: ["000000", "050505", "000000"],
                cardBackground: "111111",
                accentColor: "00F0FF",
                textColor: "FFFFFF"
            )
        case .cyberpunk:
            return Theme(
                type: .cyberpunk,
                primaryGradient: ["FF0055", "FFDD00"],
                backgroundGradient: ["050515", "0A0A25", "02020A"],
                cardBackground: "1A1A3A",
                accentColor: "FF0055",
                textColor: "FFFFFF"
            )
        }
    }
}
