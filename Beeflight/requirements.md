# Beeflight - Requirements

## 1. Functional Requirements

### 1.1 Dashboard
- FR-1.1.1: The app shall display a dashboard showing GPS and sensor data.

### 1.2 Sensor Data Display
- FR-1.2.1: The app shall display the current GPS position (latitude/longitude).
- FR-1.2.2: The app shall display the current speed in kilometers per hour (kph).
- FR-1.2.3: The app shall display the current altitude in meters (m).
- FR-1.2.4: The app shall display the current climbing speed (vertical speed) in meters per second (m/s).
- FR-1.2.5: The app shall display the current heading from the device compass.
- FR-1.2.6: The app shall display the current course (ground track direction).
- FR-1.2.7: The app shall display the number of GPS satellites in use.
- FR-1.2.8: The app shall display the current barometric pressure in hectopascals (hPa).

### 1.3 Settings
- FR-1.3.1: The app shall provide a settings screen accessible from the dashboard.
- FR-1.3.2: The app shall allow the user to configure the sensor update rate.
- FR-1.3.3: The app shall offer four update rate presets: Maximum, High, Medium, and Low.
- FR-1.3.4: The selected update rate shall control the GPS distance filter and compass heading filter.
- FR-1.3.5: The app shall persist the selected update rate between app launches.
- FR-1.3.6: The app shall allow the user to choose the appearance mode: System, Light, or Dark.
- FR-1.3.7: The app shall persist the selected appearance mode between app launches.
- FR-1.3.8: The app shall allow the user to select a color theme from predefined palettes (Standard, Ocean, Forest, Sunset, Berry).
- FR-1.3.9: Each color theme shall provide matching light and dark mode color variants.
- FR-1.3.10: The app shall persist the selected color theme between app launches.

### 1.4 Connectivity
- FR-1.4.1: The app shall function fully without an internet connection.

## 2. Non-Functional Requirements

### 2.1 Localization
- NFR-2.1.1: The app shall support English.
- NFR-2.1.2: The app shall support German.

### 2.2 Appearance
- NFR-2.2.1: The app name shall be "Beeflight".
- NFR-2.2.2: The app icon shall depict a bee.
- NFR-2.2.3: The app shall only support portrait orientation.
- NFR-2.2.4: The app shall support light and dark mode, configurable via settings (System, Light, Dark).

### 2.3 Platform and Frameworks
- NFR-2.3.1: The app shall target iOS.
- NFR-2.3.2: The app shall be built using SwiftUI.
