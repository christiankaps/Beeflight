import SwiftUI

struct SensorCardView: View {
    let title: LocalizedStringKey
    let value: String
    let unit: LocalizedStringKey
    let icon: String
    var themeColors: ThemeColors = ColorTheme.bee.colors
    var valueTrailing: String? = nil

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
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .fontDesign(.monospaced)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .foregroundStyle(themeColors.valueText)

                if let trailing = valueTrailing {
                    HStack {
                        Spacer()
                        Text(trailing)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(themeColors.cardAccent)
                    }
                }
            }

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

#Preview {
    SensorCardView(
        title: "Speed",
        value: "42.5",
        unit: "km/h",
        icon: "speedometer"
    )
    .padding()
}
