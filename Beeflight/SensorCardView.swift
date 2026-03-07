import SwiftUI

struct SensorCardView: View {
    let title: LocalizedStringKey
    let value: String
    let unit: LocalizedStringKey
    let icon: String
    var themeColors: ThemeColors = ColorTheme.bee.colors

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(themeColors.cardAccent)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(themeColors.cardAccent)
            }

            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .fontDesign(.monospaced)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .foregroundStyle(themeColors.valueText)

            Text(unit)
                .font(.caption2)
                .foregroundStyle(themeColors.unitText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(themeColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Card variant with a rotating directional arrow for heading/course tiles.
struct CompassCardView: View {
    let title: LocalizedStringKey
    let degrees: Double
    let arrowRotation: Double
    let icon: String
    let isValid: Bool
    var themeColors: ThemeColors = ColorTheme.bee.colors

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(themeColors.cardAccent)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(themeColors.cardAccent)
            }

            ZStack {
                Text(isValid ? SensorFormatters.formatHeadingDegrees(degrees) : "--")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .fontDesign(.monospaced)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .foregroundStyle(themeColors.valueText)

                HStack {
                    if isValid {
                        Image(systemName: "location.north.fill")
                            .font(.caption)
                            .foregroundStyle(themeColors.cardAccent)
                            .rotationEffect(.degrees(arrowRotation))
                    }
                    Spacer()
                    if isValid {
                        Text(SensorFormatters.cardinalDirection(for: degrees))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(themeColors.cardAccent)
                    }
                }
            }

            Text("unitDegrees")
                .font(.caption2)
                .foregroundStyle(themeColors.unitText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(themeColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    SensorCardView(
        title: "Speed",
        value: "42.5",
        unit: "km/h",
        icon: "speedometer"
    )
    .padding()
}
