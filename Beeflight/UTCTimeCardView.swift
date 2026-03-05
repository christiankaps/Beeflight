import SwiftUI

struct UTCTimeCardView: View {
    var latitude: Double
    var longitude: Double
    var themeColors: ThemeColors = ColorTheme.bee.colors

    private static let utcTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    private static let utcDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    private static let sunTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let solar = SolarCalculator.sunriseSunset(latitude: latitude, longitude: longitude, date: context.date)

            HStack {
                // Sunrise (left)
                VStack(spacing: 2) {
                    Image(systemName: "sunrise.fill")
                        .font(.caption)
                        .foregroundStyle(themeColors.cardAccent)
                    Text(solar.sunrise.map { Self.sunTimeFormatter.string(from: $0) } ?? "--:--")
                        .font(.caption)
                        .fontDesign(.monospaced)
                        .foregroundStyle(themeColors.unitText)
                }
                .frame(width: 50)

                // Time & Date (center)
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: "clock")
                            .font(.headline)
                            .foregroundStyle(themeColors.cardAccent)
                        Text("sensorUTCTime")
                            .font(.caption)
                            .foregroundStyle(themeColors.cardAccent)
                    }

                    Text(Self.utcTimeFormatter.string(from: context.date))
                        .font(.title)
                        .fontWeight(.semibold)
                        .fontDesign(.monospaced)
                        .foregroundStyle(themeColors.valueText)

                    Text(Self.utcDateFormatter.string(from: context.date))
                        .font(.subheadline)
                        .fontDesign(.monospaced)
                        .foregroundStyle(themeColors.unitText)
                }
                .frame(maxWidth: .infinity)

                // Sunset (right)
                VStack(spacing: 2) {
                    Image(systemName: "sunset.fill")
                        .font(.caption)
                        .foregroundStyle(themeColors.cardAccent)
                    Text(solar.sunset.map { Self.sunTimeFormatter.string(from: $0) } ?? "--:--")
                        .font(.caption)
                        .fontDesign(.monospaced)
                        .foregroundStyle(themeColors.unitText)
                }
                .frame(width: 50)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(themeColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    UTCTimeCardView(latitude: 48.1351, longitude: 11.5820)
        .padding()
}
