# BeeSense

A fully offline iOS sensor dashboard that displays real-time GPS, barometric, motion, and time data.

## Features

![App Screenshot](/doc/AppScreenshot_1.png)

### Sensor Dashboard

| Tile | Source | Details |
|---|---|---|
| UTC Time | GPS / System Clock | Live clock, date, UTC offset, sunrise & sunset |
| Position | CoreLocation | Latitude / Longitude with N/S E/W suffixes, offline country name |
| Altitude | CoreLocation | GPS-derived altitude |
| Pressure | CMAltimeter | Barometric pressure from the device's barometer |
| Speed | CoreLocation | Ground speed with EMA smoothing and hysteresis |
| Climbing Speed | CMAltimeter | Derived from relative altitude changes, EMA-smoothed with dead zone |
| Heading | CoreLocation | Magnetic/true heading compass with rotating arrow |
| Course | CoreLocation | Ground track direction with rotating arrow |
| G-Force | CMMotionManager | 3-axis accelerometer magnitude, EMA-smoothed |
| GPS Signal | CoreLocation | Horizontal accuracy mapped to quality percentage |

### Unit Systems

Three selectable unit systems with full conversion support:

- **Metric** — km/h, meters, m/s, hPa
- **Imperial** — mph, feet, ft/min, inHg
- **Aviation** — knots, feet, ft/min, hPa

### Themes

Five color themes, each with hand-tuned light and dark mode variants:

- Bee, Lava, Ocean, Forest, Slate

Pull down on the dashboard to cycle through themes (with haptic feedback).

### Localization

- English and German via Xcode String Catalogs (`.xcstrings`)

## Architecture

### State Management

All data models use the `@Observable` macro (Observation framework) instead of the older Combine-based `ObservableObject` / `@Published` pattern. Views receive managers as plain parameters; SwiftUI automatically tracks property access and re-renders only what changed.

### Sensor Managers

| Manager | Framework | Update Method |
|---|---|---|
| `LocationManager` | CoreLocation | `CLLocationManagerDelegate` callbacks |
| `AltimeterManager` | CoreMotion | `CMAltimeter.startRelativeAltitudeUpdates` closure |
| `MotionManager` | CoreMotion | `CMMotionManager.startAccelerometerUpdates` closure |

All managers start and stop in response to `ScenePhase` changes — sensors are active only when the app is in the foreground.

### Signal Processing

**EMA Filter** (`EMAFilter.swift`) — A time-aware exponential moving average that adapts to irregular sample intervals:

```
alpha = 1 - exp(-dt / tau)
value += alpha * (raw - value)
```

Three instances with different time constants:

| Usage | tau | Initial |
|---|---|---|
| Speed smoothing | 2.0 s | 0.0 |
| Climb rate smoothing | 2.0 s | 0.0 |
| G-force smoothing | 1.0 s | 1.0 (1G at rest) |

**Dead Zones** suppress jitter near zero:

- Speed: 0.5 m/s hysteresis — value updates only when the change exceeds the threshold
- Climb rate: 0.05 m/s absolute — values below are clamped to exactly 0.0

**Safety Clamps** prevent garbage readings:

- Speed capped at 500 m/s
- Climb rate capped at ±50 m/s
- Minimum dt guard of 10 ms on climb rate derivation

### Offline Country Detection

The app detects the user's country without any network connection:

1. **Data source**: Natural Earth 1:110m country boundaries bundled as simplified GeoJSON (194 KB, 177 countries). Public domain.
2. **Algorithm**: Ray-casting point-in-polygon test against each country's outer boundary rings, with inner holes excluded. Supports both `Polygon` and `MultiPolygon` geometries.
3. **Localization**: Country names are resolved via `Locale.current.localizedString(forRegionCode:)` using the ISO 3166-1 alpha-2 code, falling back to the English name from the dataset.
4. **Performance**: Lookups are cached and only re-run when the position moves more than ~0.1 degrees (~11 km).

### Solar Calculation

Sunrise and sunset times are computed offline using the NOAA solar position algorithm:

- Equation of Time correction for orbital eccentricity
- Solar declination from fractional year
- Hour angle solved for zenith 90.833° (standard refraction + solar disk radius)
- Returns `nil` for polar day/night conditions
- Cached per UTC day-of-year and rounded position to avoid redundant computation while still updating after meaningful movement

### Adaptive Update Rate

When automatic mode is enabled, the GPS update rate adjusts to battery state:

| Condition | Rate |
|---|---|
| Low Power Mode | Low (10 m, 5°) |
| Charging / Full | Maximum (no filter) |
| On battery | Medium (5 m, 3°) |

### Settings Persistence

All user preferences are stored in `UserDefaults` via `didSet` property observers on `AppSettings`. No Codable encoding — each property writes its raw value directly on change.

### Theming

Colors use `UIColor` dynamic trait providers bridged to SwiftUI `Color`, so each theme has separate RGB values for light and dark mode that respond automatically to system appearance changes:

```swift
Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? darkColor : lightColor })
```

### Orientation Handling

Compass arrows compensate for device rotation by reading `UIWindowScene.interfaceOrientation` and applying an offset. Portrait lock is enforced at runtime via `UIApplicationDelegate.supportedInterfaceOrientationsFor` without requiring a restart.

## UI

- **SwiftUI** with `NavigationStack`
- **Dashboard**: Full-width time and position tiles, then a 2-column `LazyVGrid` for sensor cards
- **Live clock**: `TimelineView(.periodic(from:by: 1))` drives a 1-second refresh without `Timer`
- **Pull-to-switch theme**: `onScrollGeometryChange` detects overscroll > 80pt, triggers theme cycle with `UIImpactFeedbackGenerator` haptic feedback
- **Settings**: `Form`-based with `.pickerStyle(.navigationLink)`, color swatch circles in the theme picker

## Testing

### Unit Tests (Swift Testing framework)

Focused tests using `@Test` and `#expect`:

- **SensorFormatters**: Latitude/longitude formatting, speed, altitude, climbing speed, pressure, heading normalization, cardinal directions, NaN/Infinity guards
- **LocationManager**: Speed conversion, initial values, metric validity flags
- **AltimeterManager**: Pressure unit conversion, stop/reset behavior
- **CountryDetector**: Detection for 5 countries (DE, US, JP, AU, BR), ocean returns nil, polygon-hole exclusion, localized name resolution, ISO code fallback

### UI Tests (XCTest)

- Dashboard-to-settings navigation assertion
- App launch verification
- Launch performance measurement via `XCTApplicationLaunchMetric`
- Screenshot capture across UI configurations

## Requirements

- iOS 18.6+
- Xcode 16+
- Swift 5+
- Device with GPS, barometer, and accelerometer (full functionality)

## Data Sources

- Country boundaries: [Natural Earth](https://www.naturalearthdata.com) 1:110m Admin 0 — public domain
