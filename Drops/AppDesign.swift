import SwiftUI

struct AppDesign {
    
    // MARK: - Colors
    struct Colors {
        static let base = Color(hex: "#413E3E").opacity(0.5)
        static let accent = Color(hex: "#FFFFFF") // White
        static let accent2 = Color(hex: "#bbbbbb") // White
        static let neutral = Color(hex: "#000000") // Black
        static let neutralB = Color(hex: "#413E3E").opacity(0.65) // Dark grey for Sheet Parameter Tiles
        static let imageBG = Color(hex: "#ffffff") // White

    }
    
    // MARK: - Button States
    struct ButtonStates {
         static let HighlightedState = ButtonStyleConfiguration(
            background: Colors.accent,
            textColor: Colors.neutral,
            shadow: ShadowStyles.defaultState
        )
        
        static let nextAction = ButtonStyleConfiguration(
            background: Colors.accent,
            textColor: Colors.neutral,
            shadow: ShadowStyles.defaultState
        )
        
        static let defaultState = ButtonStyleConfiguration(
            background: Colors.neutralB.opacity(0.9), // Use a semi-transparent base color
            textColor: Colors.accent,
            shadow: ShadowStyles.defaultState
        )
        
        static let inactive = ButtonStyleConfiguration(
            background: Colors.neutral.opacity(0.5),
            textColor: Colors.accent.opacity(0.3),
            shadow: ShadowStyles.none
        )
        
   /*     static func chooseImageButtonStyle(for imageLoaded: Bool) -> ButtonStyleConfiguration {
            return imageLoaded ? defaultState : nextAction
        } */
        static func chooseImageButtonStyle(imageLoaded: Bool) -> some ButtonStyle {
                let state = imageLoaded
                    ? ButtonStyleConfiguration(
                        background: Color.clear, // ✅ Let `.ultraThinMaterial` be applied at the button level
                        textColor: Colors.accent,
                        shadow: ShadowStyles.defaultState
                    )
                    : ButtonStyleConfiguration(
                        background: Colors.accent, // ✅ Default state with accent background
                        textColor: Colors.neutral,
                        shadow: ShadowStyles.defaultState
                    )

                return CustomButtonStyle(config: state)
            }
    }
    
    // MARK: - Component States (Parameter Pills)
    struct ComponentStates {
        static let dynamicParameterDefault = ComponentStyleConfiguration(
            background: Colors.neutral.opacity(1.0),
            shadow: ShadowStyles.pill
        )
        
        static let dynamicParameterActivated = ComponentStyleConfiguration(
            background: Colors.accent.opacity(1.0),
            shadow: ShadowStyles.pill
        )
    }
    
    // MARK: - Shadows & Effects
    struct ShadowStyles {
        static let none = ShadowStyle(radius: 0, x: 0, y: 0, opacity: 0)
        
        static let defaultState = ShadowStyle(radius: 4, x: 0, y: 0, opacity: 0.2) // Button default shadow
        static let pill = ShadowStyle(radius: 16, x: 0, y: 0, opacity: 1.0, color: .white)
        static let slider = ShadowStyle(radius: 4, x: 0, y: 4, opacity: 0.2, color: .black)
    }
    
    // MARK: - Button Sizes
    struct ButtonSizes {
        static let main = CGSize(width: 56, height: 56)
        static let contextual = CGSize(width: 32, height: 32)
    }
    
    // MARK: - Transitions
    struct Transitions {
        static let fade = AnyTransition.opacity.animation(.easeInOut(duration: 0.35))
    }
    // MARK: - Choose Image BG color
    static func chooseImageButtonBackground(imageLoaded: Bool) -> Color {
        return imageLoaded ? Color.clear : Colors.accent // ✅ Return Color instead of AnyView
    }
    // MARK: - Pulse Hint and Loading styles
    struct PulseHintStyle {
            static let lineWidth: CGFloat = 1.5
            static let strokeColor: Color = Colors.accent // or Colors.accent2, etc.
            static let fillColor: Color = Colors.accent   // reuse the same accent or pick a different color
        }
}

// MARK: - Supporting Structs
struct ButtonStyleConfiguration {
    let background: Color
    let textColor: Color
    let shadow: ShadowStyle
}

struct ComponentStyleConfiguration {
    let background: Color
    let shadow: ShadowStyle
}

struct ShadowStyle {
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    let opacity: Double
    let color: Color?
    
    init(radius: CGFloat, x: CGFloat, y: CGFloat, opacity: Double, color: Color? = nil) {
        self.radius = radius
        self.x = x
        self.y = y
        self.opacity = opacity
        self.color = color ?? .black
    }
}

// MARK: - HEX Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        if hex.count == 6 {
            r = Double((int >> 16) & 0xFF) / 255.0
            g = Double((int >> 8) & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        } else {
            r = 1.0
            g = 1.0
            b = 1.0
        }
        self.init(red: r, green: g, blue: b)
    }
}
