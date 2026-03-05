import SwiftUI
import UIKit

// MARK: - ThemeColors

struct ThemeColors {
    let cardBackground: Color
    let cardAccent: Color
    let valueText: Color
    let unitText: Color
    let tint: Color
}

// MARK: - ColorTheme

enum ColorTheme: String, CaseIterable, Identifiable {
    case bee = "bee"
    case ocean = "ocean"
    case forest = "forest"
    case sunset = "sunset"
    case berry = "berry"
    case slate = "slate"
    case arctic = "arctic"
    case lava = "lava"
    case mint = "mint"

    var id: String { rawValue }

    var colors: ThemeColors {
        switch self {
        case .bee:
            return ThemeColors(
                cardBackground: adaptive(
                    light: UIColor(red: 1.0, green: 0.96, blue: 0.82, alpha: 1),
                    dark: UIColor(red: 0.18, green: 0.15, blue: 0.08, alpha: 1)
                ),
                cardAccent: adaptive(
                    light: UIColor(red: 0.55, green: 0.45, blue: 0.05, alpha: 1),
                    dark: UIColor(red: 0.95, green: 0.80, blue: 0.20, alpha: 1)
                ),
                valueText: adaptive(
                    light: UIColor(red: 0.12, green: 0.10, blue: 0.05, alpha: 1),
                    dark: UIColor(red: 1.0, green: 0.95, blue: 0.75, alpha: 1)
                ),
                unitText: adaptive(
                    light: UIColor(red: 0.50, green: 0.42, blue: 0.20, alpha: 1),
                    dark: UIColor(red: 0.70, green: 0.62, blue: 0.35, alpha: 1)
                ),
                tint: adaptive(
                    light: UIColor(red: 0.85, green: 0.65, blue: 0.0, alpha: 1),
                    dark: UIColor(red: 1.0, green: 0.80, blue: 0.0, alpha: 1)
                )
            )
        case .ocean:
            return ThemeColors(
                cardBackground: adaptive(
                    light: UIColor(red: 0.91, green: 0.96, blue: 1.0, alpha: 1),
                    dark: UIColor(red: 0.10, green: 0.15, blue: 0.25, alpha: 1)
                ),
                cardAccent: adaptive(
                    light: UIColor(red: 0.20, green: 0.50, blue: 0.75, alpha: 1),
                    dark: UIColor(red: 0.45, green: 0.72, blue: 0.95, alpha: 1)
                ),
                valueText: adaptive(
                    light: UIColor(red: 0.05, green: 0.15, blue: 0.30, alpha: 1),
                    dark: UIColor(red: 0.85, green: 0.92, blue: 1.0, alpha: 1)
                ),
                unitText: adaptive(
                    light: UIColor(red: 0.40, green: 0.55, blue: 0.70, alpha: 1),
                    dark: UIColor(red: 0.50, green: 0.65, blue: 0.80, alpha: 1)
                ),
                tint: adaptive(
                    light: UIColor(red: 0.00, green: 0.40, blue: 0.80, alpha: 1),
                    dark: UIColor(red: 0.30, green: 0.65, blue: 1.0, alpha: 1)
                )
            )
        case .forest:
            return ThemeColors(
                cardBackground: adaptive(
                    light: UIColor(red: 0.92, green: 0.97, blue: 0.91, alpha: 1),
                    dark: UIColor(red: 0.10, green: 0.18, blue: 0.12, alpha: 1)
                ),
                cardAccent: adaptive(
                    light: UIColor(red: 0.25, green: 0.55, blue: 0.30, alpha: 1),
                    dark: UIColor(red: 0.45, green: 0.78, blue: 0.50, alpha: 1)
                ),
                valueText: adaptive(
                    light: UIColor(red: 0.10, green: 0.22, blue: 0.10, alpha: 1),
                    dark: UIColor(red: 0.85, green: 0.95, blue: 0.87, alpha: 1)
                ),
                unitText: adaptive(
                    light: UIColor(red: 0.40, green: 0.58, blue: 0.42, alpha: 1),
                    dark: UIColor(red: 0.50, green: 0.70, blue: 0.52, alpha: 1)
                ),
                tint: adaptive(
                    light: UIColor(red: 0.15, green: 0.55, blue: 0.20, alpha: 1),
                    dark: UIColor(red: 0.35, green: 0.80, blue: 0.40, alpha: 1)
                )
            )
        case .sunset:
            return ThemeColors(
                cardBackground: adaptive(
                    light: UIColor(red: 1.0, green: 0.95, blue: 0.90, alpha: 1),
                    dark: UIColor(red: 0.22, green: 0.12, blue: 0.08, alpha: 1)
                ),
                cardAccent: adaptive(
                    light: UIColor(red: 0.80, green: 0.40, blue: 0.15, alpha: 1),
                    dark: UIColor(red: 0.95, green: 0.60, blue: 0.30, alpha: 1)
                ),
                valueText: adaptive(
                    light: UIColor(red: 0.30, green: 0.12, blue: 0.05, alpha: 1),
                    dark: UIColor(red: 1.0, green: 0.92, blue: 0.85, alpha: 1)
                ),
                unitText: adaptive(
                    light: UIColor(red: 0.65, green: 0.45, blue: 0.35, alpha: 1),
                    dark: UIColor(red: 0.75, green: 0.58, blue: 0.48, alpha: 1)
                ),
                tint: adaptive(
                    light: UIColor(red: 0.90, green: 0.40, blue: 0.10, alpha: 1),
                    dark: UIColor(red: 1.0, green: 0.55, blue: 0.20, alpha: 1)
                )
            )
        case .berry:
            return ThemeColors(
                cardBackground: adaptive(
                    light: UIColor(red: 0.96, green: 0.92, blue: 0.98, alpha: 1),
                    dark: UIColor(red: 0.15, green: 0.10, blue: 0.20, alpha: 1)
                ),
                cardAccent: adaptive(
                    light: UIColor(red: 0.55, green: 0.22, blue: 0.65, alpha: 1),
                    dark: UIColor(red: 0.75, green: 0.50, blue: 0.90, alpha: 1)
                ),
                valueText: adaptive(
                    light: UIColor(red: 0.20, green: 0.08, blue: 0.28, alpha: 1),
                    dark: UIColor(red: 0.92, green: 0.85, blue: 0.98, alpha: 1)
                ),
                unitText: adaptive(
                    light: UIColor(red: 0.50, green: 0.38, blue: 0.58, alpha: 1),
                    dark: UIColor(red: 0.62, green: 0.52, blue: 0.72, alpha: 1)
                ),
                tint: adaptive(
                    light: UIColor(red: 0.60, green: 0.15, blue: 0.70, alpha: 1),
                    dark: UIColor(red: 0.78, green: 0.40, blue: 0.95, alpha: 1)
                )
            )
        case .slate:
            return ThemeColors(
                cardBackground: adaptive(
                    light: UIColor(red: 0.94, green: 0.94, blue: 0.95, alpha: 1),
                    dark: UIColor(red: 0.14, green: 0.14, blue: 0.16, alpha: 1)
                ),
                cardAccent: adaptive(
                    light: UIColor(red: 0.40, green: 0.42, blue: 0.48, alpha: 1),
                    dark: UIColor(red: 0.65, green: 0.67, blue: 0.72, alpha: 1)
                ),
                valueText: adaptive(
                    light: UIColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1),
                    dark: UIColor(red: 0.90, green: 0.90, blue: 0.92, alpha: 1)
                ),
                unitText: adaptive(
                    light: UIColor(red: 0.50, green: 0.50, blue: 0.55, alpha: 1),
                    dark: UIColor(red: 0.55, green: 0.55, blue: 0.60, alpha: 1)
                ),
                tint: adaptive(
                    light: UIColor(red: 0.35, green: 0.38, blue: 0.45, alpha: 1),
                    dark: UIColor(red: 0.55, green: 0.58, blue: 0.68, alpha: 1)
                )
            )
        case .arctic:
            return ThemeColors(
                cardBackground: adaptive(
                    light: UIColor(red: 0.93, green: 0.97, blue: 1.0, alpha: 1),
                    dark: UIColor(red: 0.08, green: 0.12, blue: 0.18, alpha: 1)
                ),
                cardAccent: adaptive(
                    light: UIColor(red: 0.30, green: 0.60, blue: 0.75, alpha: 1),
                    dark: UIColor(red: 0.55, green: 0.82, blue: 0.95, alpha: 1)
                ),
                valueText: adaptive(
                    light: UIColor(red: 0.08, green: 0.18, blue: 0.28, alpha: 1),
                    dark: UIColor(red: 0.88, green: 0.95, blue: 1.0, alpha: 1)
                ),
                unitText: adaptive(
                    light: UIColor(red: 0.40, green: 0.55, blue: 0.65, alpha: 1),
                    dark: UIColor(red: 0.50, green: 0.68, blue: 0.78, alpha: 1)
                ),
                tint: adaptive(
                    light: UIColor(red: 0.15, green: 0.55, blue: 0.75, alpha: 1),
                    dark: UIColor(red: 0.40, green: 0.78, blue: 0.95, alpha: 1)
                )
            )
        case .lava:
            return ThemeColors(
                cardBackground: adaptive(
                    light: UIColor(red: 1.0, green: 0.93, blue: 0.92, alpha: 1),
                    dark: UIColor(red: 0.20, green: 0.10, blue: 0.10, alpha: 1)
                ),
                cardAccent: adaptive(
                    light: UIColor(red: 0.75, green: 0.22, blue: 0.18, alpha: 1),
                    dark: UIColor(red: 0.95, green: 0.45, blue: 0.40, alpha: 1)
                ),
                valueText: adaptive(
                    light: UIColor(red: 0.25, green: 0.08, blue: 0.08, alpha: 1),
                    dark: UIColor(red: 1.0, green: 0.90, blue: 0.88, alpha: 1)
                ),
                unitText: adaptive(
                    light: UIColor(red: 0.60, green: 0.38, blue: 0.35, alpha: 1),
                    dark: UIColor(red: 0.72, green: 0.52, blue: 0.50, alpha: 1)
                ),
                tint: adaptive(
                    light: UIColor(red: 0.82, green: 0.18, blue: 0.12, alpha: 1),
                    dark: UIColor(red: 1.0, green: 0.40, blue: 0.32, alpha: 1)
                )
            )
        case .mint:
            return ThemeColors(
                cardBackground: adaptive(
                    light: UIColor(red: 0.90, green: 0.98, blue: 0.96, alpha: 1),
                    dark: UIColor(red: 0.08, green: 0.18, blue: 0.16, alpha: 1)
                ),
                cardAccent: adaptive(
                    light: UIColor(red: 0.15, green: 0.58, blue: 0.50, alpha: 1),
                    dark: UIColor(red: 0.35, green: 0.82, blue: 0.72, alpha: 1)
                ),
                valueText: adaptive(
                    light: UIColor(red: 0.05, green: 0.20, blue: 0.18, alpha: 1),
                    dark: UIColor(red: 0.85, green: 0.98, blue: 0.95, alpha: 1)
                ),
                unitText: adaptive(
                    light: UIColor(red: 0.35, green: 0.55, blue: 0.50, alpha: 1),
                    dark: UIColor(red: 0.48, green: 0.68, blue: 0.62, alpha: 1)
                ),
                tint: adaptive(
                    light: UIColor(red: 0.10, green: 0.60, blue: 0.50, alpha: 1),
                    dark: UIColor(red: 0.25, green: 0.85, blue: 0.70, alpha: 1)
                )
            )
        }
    }

    /// Representative swatch colors for the settings picker preview
    var swatchColors: [Color] {
        let c = colors
        return [c.tint, c.cardAccent, c.cardBackground]
    }

    // MARK: - Helper

    /// Creates a SwiftUI Color that adapts between light and dark modes
    private func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        })
    }
}
