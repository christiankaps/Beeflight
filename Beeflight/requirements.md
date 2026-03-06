# Beesense - Requirements

## 1. Functional Requirements

### 1.1 Dashboard
- FR-1.1.1: The app shall display a dashboard showing GPS, barometric, motion, and time data in a 2-column grid layout.
- FR-1.1.2: The dashboard scroll bar shall be hidden.

### 1.2 Sensor Data Display
- FR-1.2.1: The app shall display the current GPS position (latitude and longitude) with 6 decimal places.
- FR-1.2.2: The app shall display the current speed, converted to the selected unit system.
- FR-1.2.3: The app shall display the current altitude, converted to the selected unit system.
- FR-1.2.4: The app shall display the climbing speed (vertical rate) derived from barometric pressure changes, converted to the selected unit system.
- FR-1.2.5: The app shall display the current compass heading (0–359°) with a cardinal direction label (N, NE, E, SE, S, SW, W, NW) and a rotating arrow pointing to north.
- FR-1.2.6: The app shall display the current ground track course (0–359°) with a cardinal direction label and a rotating arrow pointing in the direction of travel relative to the phone's heading. When not moving, the course shall display "--".
- FR-1.2.7: The app shall display the GPS signal quality as a percentage (0%, 25%, 50%, 75%, 100%) based on horizontal accuracy.
- FR-1.2.8: The app shall display the current barometric pressure, converted to the selected unit system.
- FR-1.2.9: The app shall display the current G-force with 1 decimal place.
- FR-1.2.10: The climbing speed shall show a +/- sign prefix, except when the value rounds to zero.

### 1.3 UTC Time Display
- FR-1.3.1: The app shall display the current UTC time (HH:mm:ss) and date (dd.MM.yyyy) in a full-width card.
- FR-1.3.2: The app shall display sunrise and sunset times (in UTC) on the left and right sides of the time card, calculated from the current GPS position using the NOAA solar algorithm.
- FR-1.3.3: The app shall display the device's current time zone abbreviation and UTC offset (e.g. "CET (UTC +1)").

### 1.4 Sensor Processing
- FR-1.4.1: Speed values shall be smoothed using a time-aware exponential moving average (alpha = 1 - exp(-dt/tau), tau = 2s) with hysteresis (0.5 m/s) and clamped to a maximum of 500 m/s. Invalid speed values and readings with negative speed accuracy shall be ignored.
- FR-1.4.2: Climbing speed shall be derived from CMAltimeter relative altitude changes, smoothed with time-aware EMA (tau = 2s) and clamped to ±50 m/s.
- FR-1.4.3: G-force shall be calculated from 3-axis accelerometer data, smoothed with time-aware EMA (tau = 2s) at a 10 Hz update rate.
- FR-1.4.4: Compass arrows shall compensate for the current interface orientation so they remain correct in both portrait and landscape.

### 1.5 Settings
- FR-1.5.1: The app shall provide a settings screen accessible from the dashboard toolbar.
- FR-1.5.2: The app shall offer an automatic update rate mode (enabled by default) that adjusts based on battery state: maximum when charging/full, medium on battery, low in Low Power Mode.
- FR-1.5.3: The app shall allow manual selection of four update rate presets (Maximum, High, Medium, Low) when automatic mode is disabled.
- FR-1.5.4: The selected update rate shall control the GPS distance filter and compass heading filter.
- FR-1.5.5: The app shall allow the user to select a unit system: Metric (km/h, m, m/s, hPa), Imperial (mph, ft, ft/min, inHg), or Aviation (kn, ft, ft/min, hPa).
- FR-1.5.6: The app shall allow the user to choose the appearance mode: System, Light, or Dark.
- FR-1.5.7: The app shall allow the user to select a color theme from 9 predefined palettes: Bee, Sunset, Lava, Berry, Ocean, Arctic, Mint, Forest, Slate (ordered by color spectrum).
- FR-1.5.8: Each color theme shall provide adaptive light and dark mode color variants.
- FR-1.5.9: The app shall allow the user to lock the orientation to portrait mode.
- FR-1.5.10: All settings shall be persisted between app launches using UserDefaults.
- FR-1.5.11: The theme highlight color in settings shall update immediately when the theme is changed.

### 1.6 Permissions
- FR-1.6.1: The app shall request location permission (When In Use) on first launch.
- FR-1.6.2: The app shall check location and motion permissions on every app launch and when returning to the foreground.
- FR-1.6.3: If permissions are denied or restricted, the app shall display an alert with an option to open the device Settings app.

### 1.7 Connectivity
- FR-1.7.1: The app shall function fully without an internet connection.

## 2. Non-Functional Requirements

### 2.1 Localization
- NFR-2.1.1: The app shall use English as the default language.
- NFR-2.1.2: The app shall support German translations for all UI strings, including sensor labels, settings, themes, units, and permission messages.
- NFR-2.1.3: Localization shall use String Catalogs (.xcstrings).

### 2.2 Appearance
- NFR-2.2.1: The app name shall be "Beesense".
- NFR-2.2.2: The app icon shall depict a bee with light, dark, and tinted variants.
- NFR-2.2.3: The app shall support portrait and landscape orientation, with an optional setting to lock to portrait.
- NFR-2.2.4: The app shall support light and dark mode, configurable via settings (System, Light, Dark).
- NFR-2.2.5: The default color theme shall be "Bee" (yellow/black).

### 2.3 Platform and Frameworks
- NFR-2.3.1: The app shall target iOS.
- NFR-2.3.2: The app shall be built using SwiftUI with the @Observable macro (not Combine/ObservableObject).
- NFR-2.3.3: The app shall use CoreLocation for GPS data, CoreMotion (CMAltimeter) for barometric pressure and altitude, and CoreMotion (CMMotionManager) for accelerometer data.

### 2.4 Performance
- NFR-2.4.1: Release builds shall use GCC optimization level 3 and Swift whole module optimization.
- NFR-2.4.2: Battery monitoring shall be enabled to support automatic update rate adjustment.
