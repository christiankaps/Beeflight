import SwiftUI

struct UTCTimeCardView: View {
    var latitude: Double
    var longitude: Double
    var themeColors: ThemeColors = ColorTheme.bee.colors

    @State private var cachedDayOfYear: Int = -1
    @State private var sunriseString: String = "--:--"
    @State private var sunsetString: String = "--:--"

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

    private static var utcOffsetString: String {
        let tz = TimeZone.current
        let seconds = tz.secondsFromGMT()
        let hours = seconds / 3600
        let minutes = abs(seconds % 3600) / 60
        let sign = hours >= 0 ? "+" : ""
        let abbr = tz.abbreviation() ?? ""
        if minutes == 0 {
            return "\(abbr) (UTC \(sign)\(hours))"
        } else {
            return "\(abbr) (UTC \(sign)\(hours):\(String(format: "%02d", minutes)))"
        }
    }

    private static var utcCalendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    private func updateSolarIfNeeded(for date: Date) {
        let day = Self.utcCalendar.ordinality(of: .day, in: .year, for: date) ?? -1
        guard day != cachedDayOfYear else { return }
        cachedDayOfYear = day
        let solar = SolarCalculator.sunriseSunset(latitude: latitude, longitude: longitude, date: date)
        sunriseString = solar.sunrise.map { Self.sunTimeFormatter.string(from: $0) } ?? "--:--"
        sunsetString = solar.sunset.map { Self.sunTimeFormatter.string(from: $0) } ?? "--:--"
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = context.date

            HStack {
                // Sunrise (left)
                VStack(spacing: 2) {
                    Image(systemName: "sunrise.fill")
                        .font(.caption)
                        .foregroundStyle(themeColors.cardAccent)
                    Text(sunriseString)
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

                    Text(Self.utcTimeFormatter.string(from: now))
                        .font(.title)
                        .fontWeight(.semibold)
                        .fontDesign(.monospaced)
                        .foregroundStyle(themeColors.valueText)

                    Text(Self.utcDateFormatter.string(from: now))
                        .font(.subheadline)
                        .fontDesign(.monospaced)
                        .foregroundStyle(themeColors.unitText)

                    Text(Self.utcOffsetString)
                        .font(.caption2)
                        .foregroundStyle(themeColors.unitText)
                }
                .frame(maxWidth: .infinity)

                // Sunset (right)
                VStack(spacing: 2) {
                    Image(systemName: "sunset.fill")
                        .font(.caption)
                        .foregroundStyle(themeColors.cardAccent)
                    Text(sunsetString)
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
            .onChange(of: now) { updateSolarIfNeeded(for: now) }
            .onAppear { updateSolarIfNeeded(for: now) }
        }
    }
}

#Preview {
    UTCTimeCardView(latitude: 48.1351, longitude: 11.5820)
        .padding()
}
