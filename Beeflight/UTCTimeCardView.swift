import SwiftUI

struct UTCTimeCardView: View {
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

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(spacing: 6) {
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

                Text("unitUTC")
                    .font(.caption2)
                    .foregroundStyle(themeColors.unitText)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(themeColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    UTCTimeCardView()
        .padding()
}
