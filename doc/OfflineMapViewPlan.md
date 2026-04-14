# Offline Map View — Feature Plan

Status: **Draft / awaiting approval** &nbsp;·&nbsp; Branch: `claude/add-offline-map-view-W3ARZ`

## 1. Goal

Add an offline-first map view to Beesense that:

- Shows the user's current location on a map.
- Covers the whole globe without a network connection.
- Lets the user download regions at multiple detail (zoom) tiers for offline use.
- Supports free pinch-zoom, pan, and rotate.

The feature must preserve FR-1.7.1 ("The app shall function fully without an
internet connection"). The app never *requires* the network, but may *use* it
when the user explicitly downloads a region.

## 2. Non-goals

- Turn-by-turn navigation / routing.
- Search / geocoding.
- 3-D terrain or satellite imagery.
- Tile hosting infrastructure (tiles are bundled or downloaded from a
  configured open source; we do not run a server).

## 3. Rendering engine

**Chosen: MapLibre Native iOS** (SPM:
`maplibre-gl-native-distribution`, BSD-2 / open source fork of the last
open-source Mapbox GL Native).

Alternatives considered:

| Option | Whole globe offline? | Free zoom/pan | License | Verdict |
|---|---|---|---|---|
| `MKMapView` (Apple Maps) | No — caching Apple tiles is not permitted by the ToS | Yes | Apple EULA | Rejected |
| `MKTileOverlay` + raster OSM | Yes, but huge on-disk size at high zoom; no built-in offline region download | Yes | OSM ODbL | Works but high storage & manual pack mgmt |
| **MapLibre Native** | **Yes — first-class offline region API, vector tiles** | **Yes** | **BSD-2** | **Chosen** |
| Protomaps `.pmtiles` + MapLibre | Yes — single-file global archive | Yes | CC0 / BSD-2 | Viable as tile source within MapLibre |

MapLibre gives us vector tiles (smaller, re-stylable), a native offline region
downloader (`MLNOfflineStorage.addPack`), background-safe progress callbacks,
and it renders through Metal for smooth gestures.

## 4. Tile source and style

- **Base data:** OpenMapTiles schema vector tiles (OSM data, CC-BY / ODbL
  attribution required) packaged as `.mbtiles`, or Protomaps `.pmtiles`.
- **Style JSON:** bundled in the app (`style-light.json`, `style-dark.json`),
  so no runtime fetch of the style is needed. Both styles reference the same
  bundled tileset, only the colors differ — matches FR-1.5.6 / NFR-2.2.4.
- **Glyphs:** MapLibre needs PBF glyph ranges for text labels. We bundle a
  minimal Noto Sans (Regular + Bold) set (~3 MB). OFL license.
- **Sprites:** bundled PNG + JSON sprite sheet for map icons.
- **Attribution overlay:** the map view always shows
  "© OpenStreetMap contributors" (and OpenMapTiles / Protomaps as appropriate).
  Required by license.

## 5. Offline coverage strategy

### 5.1 Always-available world base

Bundle a world pack at **zoom 0–5** (~15–25 MB compressed vector mbtiles).
Guarantees a usable map everywhere on first launch, zero network needed.

### 5.2 On-demand regional packs

The user picks a region (current map viewport, or a named preset) and a
detail tier:

| Tier | Zoom range | Approx use | Approx size per 100×100 km |
|---|---|---|---|
| Overview  | z6 – z9  | country / large region scale | ~2–5 MB |
| Regional  | z10 – z12 | metro / state scale | ~15–40 MB |
| Detailed  | z13 – z15 | streets, buildings | ~80–250 MB |

Exact numbers depend on the area's data density; we show a pre-download
estimate using `MLNTilePyramidOfflineRegion` byte counting.

Operations: **add, pause, resume, delete, rename, show size**.

### 5.3 Storage

- Packs stored in MapLibre's SQLite cache under `Application Support/`.
- User-set soft cap `mapMaxCacheMB` (default 500 MB). When exceeded we warn
  the user before the next download.
- "Clear all map data" button in settings.

## 6. Integration with existing app

### 6.1 Navigation

Add a `map` toolbar button to `DashboardView` next to the existing
`gearshape`, navigating to `MapView`. Preserve the existing pull-to-cycle-theme
gesture on the dashboard; the map view does **not** intercept it.

### 6.2 Location

Re-use `LocationManager` (no new CoreLocation instance). Read
`latitude`, `longitude`, `heading`, `course`, `horizontalAccuracy`.
Render:

- Blue-dot annotation at current position, tinted with
  `settings.themeColors.tint`.
- Accuracy circle radius = `horizontalAccuracy` in meters.
- Heading cone when `mapFollowMode == .followWithHeading`.

### 6.3 Scene phase

Mirror the existing pattern in `ContentView.onChange(of: scenePhase)`:

- `.background` → pause any active downloads, stop map idle timers.
- `.active` → resume.

### 6.4 Theming

Map style switches `style-light.json` ↔ `style-dark.json` from
`AppSettings.appearanceMode` + `UITraitCollection.userInterfaceStyle`.
Location marker uses `settings.themeColors.tint`.

## 7. File layout

```
Beeflight/
  Map/
    MapView.swift                    // SwiftUI UIViewRepresentable for MLNMapView
    OfflineMapManager.swift          // @Observable: packs, progress, totals
    OfflineRegionPicker.swift        // pick bbox + detail tier + confirm
    OfflinePackListView.swift        // list / pause / resume / delete
    MapStyle.swift                   // load bundled style JSON, dark/light swap
    MapAttributionView.swift         // OSM / OpenMapTiles attribution overlay
    Resources/
      style-light.json
      style-dark.json
      sprites/sprite.json, sprite.png, sprite@2x.{json,png}
      glyphs/Noto Sans Regular/0-255.pbf ... (ranges)
      world-z0-z5.mbtiles            // bundled global base
```

New Swift Package dependency in `Beeflight.xcodeproj`:
`https://github.com/maplibre/maplibre-gl-native-distribution` (pin a released
tag, e.g. `6.x`).

## 8. New AppSettings keys

| Key | Type | Default | Description |
|---|---|---|---|
| `mapFollowMode` | enum `off` / `follow` / `followWithHeading` | `follow` | Center behavior |
| `mapStyleVariant` | enum `auto` / `light` / `dark` | `auto` | Map style override |
| `mapMaxCacheMB` | Int | 500 | Soft cap on map cache |

All persisted in `UserDefaults` via `didSet`, matching the existing
`AppSettings` pattern.

## 9. Proposed requirement additions (to append to `requirements.md`)

### 1.8 Offline Map

- **FR-1.8.1** The app shall provide an offline map view accessible from the
  dashboard toolbar.
- **FR-1.8.2** The map shall render worldwide coverage without a network
  connection at zoom levels 0–5 out of the box (bundled base tiles).
- **FR-1.8.3** The map shall support pinch zoom, pan, and rotate with a
  maximum zoom level of at least 15.
- **FR-1.8.4** The map shall display the user's current location, accuracy
  circle, and — when `mapFollowMode == .followWithHeading` — a heading cone.
- **FR-1.8.5** The user shall be able to download the currently visible
  region at one of three detail tiers (Overview z6–9 / Regional z10–12 /
  Detailed z13–15) for offline use, and see a size estimate before starting.
- **FR-1.8.6** The user shall be able to list, pause, resume, and delete
  downloaded map packs, and see the total on-disk cache size.
- **FR-1.8.7** The map shall adopt the app's light/dark appearance per
  `AppSettings.appearanceMode` and tint the location marker with the active
  theme tint.
- **FR-1.8.8** The map view shall display OSM / tile-provider attribution
  visibly.

### Non-functional

- **NFR-2.4.6** Active map pack downloads shall be paused when the app enters
  the background and resumed when it becomes active.
- **NFR-2.5.1** The total app bundle size shall not exceed 150 MB (world
  base + MapLibre binary + existing assets).

## 10. Testing plan

### Unit

- `OfflineMapManager`
  - Tier → zoom-range mapping.
  - Pack dedupe by (bbox, tier).
  - Size-estimate formatting (`ByteCountFormatter`).
- `MapStyle`
  - Dark/light resolution from `AppearanceMode` + system trait.
- Bbox / tile-math helpers if any.

### UI (XCTest)

- Open map from dashboard; assert `MLNMapView` hosting view appears within
  2 s.
- With simulator in airplane mode: map must render (bundled z0–5).
- Toggle follow-with-heading: marker rotates as heading changes (driven via
  mocked `LocationManager` if feasible, else smoke test).
- Delete all packs: cache size returns to baseline.

### Manual

- Fresh install, no network, launch, open map, zoom to z5 anywhere → tiles
  render.
- Download "current view" at each tier, kill app, relaunch offline, pan to
  region → detail available up to the tier.

## 11. Risks & open questions

1. **Bundle size budget** — adding ~25 MB world base + ~10 MB MapLibre binary
   + fonts/sprites lands us around ~40 MB on top of current app. Needs
   product confirmation; if too large, drop the bundled world to z0–3 (~3 MB)
   and require the user to download their continent at first use (with an
   on-first-launch prompt).
2. **Tile licensing / attribution** — confirm choice between OpenMapTiles
   (CC-BY, requires attribution + branding) vs. Protomaps (CC0 planet dumps,
   attribution still required for underlying OSM data). Recommend Protomaps
   for simpler redistribution.
3. **Glyph / font choice** — Noto Sans covers Latin + common diacritics;
   CJK coverage would roughly triple font size. Scope: start with Latin +
   Cyrillic + Greek, document limitation.
4. **SPM + MapLibre on iOS 17 min target** — MapLibre distribution currently
   supports iOS 12+, Metal-only on recent versions. Confirm on first build.
5. **Battery impact of background downloads** — downloads are foreground-only
   per NFR-2.4.6 to stay consistent with existing scene-phase pattern.
6. **Testability of `UIViewRepresentable`** — MapLibre is hard to unit-test;
   concentrate on testing our pure-Swift manager and let the wrapper be
   smoke-tested via UI tests.

## 12. Implementation order (once approved)

1. Add SPM dependency; create `MapView` skeleton rendering bundled world.
2. `OfflineMapManager` + bundled base tileset wiring.
3. Current-location annotation + follow modes via `LocationManager`.
4. Region picker + download flow + progress UI.
5. Offline pack list, delete, cache size, clear-all (in `SettingsView`).
6. Light/dark style switching + tint + attribution overlay.
7. Localization (EN/DE) for all new strings.
8. Tests, docs, update `requirements.md` and `README.md`.

Each step is independently reviewable and behind the existing scene-phase
lifecycle.
