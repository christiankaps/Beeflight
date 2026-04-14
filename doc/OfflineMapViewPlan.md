# Offline Map View — Feature Plan

Status: **Implemented** &nbsp;·&nbsp; Branch: `claude/add-offline-map-view-W3ARZ`

## 1. Goal

Add an offline-first map view to Beesense that:

- Shows the user's current location on a map.
- Covers the whole globe without a network connection.
- Lets the user download the **whole globe** at different detail (zoom)
  levels for offline use. No regional / bbox selection — one choice, world-wide.
- Supports free pinch-zoom, pan, and rotate.

The feature must preserve FR-1.7.1 ("The app shall function fully without an
internet connection"). The app never *requires* the network, but may *use* it
when the user explicitly downloads a higher-detail global pack.

## 2. Non-goals

- Regional / bounding-box downloads. (Explicitly out of scope.)
- Turn-by-turn navigation / routing.
- Search / geocoding.
- 3-D terrain or satellite imagery.
- Running our own tile hosting infrastructure.

## 3. Rendering engine

**Chosen: Apple `MapKit` with a custom `MKTileOverlay` subclass** backed by
an `.mbtiles` SQLite archive.

Why not MapLibre (the previous draft):

- Adding an SPM dependency (~10 MB binary) is a significant footprint change
  for a single screen.
- MapKit's `MKTileOverlay` with `canReplaceMapContent = true` fully replaces
  Apple's base map with our tiles — Apple's own tiles are never loaded, so
  the view works fully offline.
- MapKit gives us pinch-zoom, pan, rotate, user-location puck, heading cone,
  and annotations for free.
- The `.mbtiles` (SQLite) format is an open, simple container for raster PNG
  tiles. Reading it requires only the system-provided `sqlite3` C library
  (no new dependencies).

Constraints this implies:

- Tiles are raster PNG (not vector). Slightly larger on disk than vector,
  but simpler to produce and render.
- We do **not** cache Apple Maps tiles (that would violate the Apple Maps
  ToS). We only render our own raster tiles.

## 4. Tile source

Tile packs are OSM-derived raster `.mbtiles` files (e.g. generated with
`tilemaker`, `mbutil`, or downloaded from an OSM raster tile provider that
permits redistribution under ODbL, such as self-hosted OpenStreetMap Carto
renders).

- **Built-in base** — a tiny global `.mbtiles` at z0–z3 is bundled in the
  app (a few MB). Guarantees a usable globe on first launch, offline.
- **Downloadable global packs** — the user picks one detail tier; the app
  downloads a single global `.mbtiles` file over HTTPS, stores it under
  `Application Support/`, and the overlay switches to reading from it.

Exact URLs for downloadable packs live in a single `MapTileTier.swift`
constants table and are intended to be populated with a CDN-hosted URL
before shipping. The code compiles and runs with placeholder URLs; download
will simply fail until real URLs are configured.

Attribution: "© OpenStreetMap contributors" is displayed on the map view.

## 5. Offline coverage strategy — whole-globe tiers

| Tier | Zoom range | Global size (approx) | Use |
|---|---|---|---|
| Built-in | z0 – z3 | ~1–3 MB, bundled | Always available; continent-level |
| Standard | z0 – z6 | ~150–250 MB | Large-town-level worldwide |
| Detailed | z0 – z8 | ~1.5–2.5 GB | Town-level worldwide |

Only **one** downloaded tier is active at a time. Downloading the *Detailed*
pack replaces the *Standard* pack (if any). A bundled Built-in pack is
always present as fallback.

Size numbers are order-of-magnitude estimates; actual numbers come from
whichever tileset we package, and the UI shows the real byte size once the
file is on disk.

Operations in the settings:

- **Download** the chosen tier (with progress, cancel).
- **Delete** the downloaded pack (reverts to Built-in).
- **Show** current tier and cache size on disk.

Rationale for dropping Detailed≥z9: worldwide z9 is ~10 GB+, z12 hundreds
of GB. That's unreasonable on a phone. Users who need street-level detail
should not rely on this app for that; we optimize for the "any map anywhere
offline" use case.

## 6. Integration with existing app

### 6.1 Navigation

A `map` toolbar button on `DashboardView`, next to the existing `gearshape`,
pushes `OfflineMapScreen` onto the existing `NavigationStack`. The
pull-to-cycle-theme gesture on the dashboard is unaffected (the map screen
is a separate destination).

### 6.2 Location

Re-use the existing `LocationManager`. `MKMapView.showsUserLocation = true`
renders the blue puck. `MKUserTrackingMode` handles follow / follow-with-
heading; we expose it through `mapFollowMode` in `AppSettings`.

### 6.3 Scene phase

Mirror the existing pattern in `ContentView.onChange(of: scenePhase)`:

- `.background` → cancel active download (URLSession task).
- `.active` → no auto-resume; user must tap Download again.

This is simpler and safer than tracking resumeData across launches; global
packs are a one-shot operation.

### 6.4 Theming

`MKMapView` doesn't theme our raster tiles, but we tint the user-location
puck and UI controls with `settings.themeColors.tint`. Appearance (light/
dark) applies to the surrounding SwiftUI chrome. Raster tiles themselves
are a fixed style — a future enhancement could offer a dark raster pack.

## 7. File layout

```
Beeflight/
  Map/
    MBTilesStore.swift          // sqlite3 reader for .mbtiles
    MapTileTier.swift           // tiers: builtin / standard / detailed
    OfflineTileOverlay.swift    // MKTileOverlay subclass
    OfflineMapManager.swift     // @Observable: active tier, download, cache
    MapView.swift               // UIViewRepresentable over MKMapView
    OfflineMapScreen.swift      // NavigationStack destination
    MapAttributionView.swift    // "© OpenStreetMap contributors"
    MapDownloadView.swift       // settings sheet: pick tier, download, delete
    Resources/
      world-z0-z3.mbtiles       // bundled base (placeholder until provided)
```

No new SPM dependency. Uses `MapKit`, `CoreLocation`, `SQLite3`
(system-provided) only.

## 8. New AppSettings keys

| Key | Type | Default | Description |
|---|---|---|---|
| `mapFollowMode` | enum `off` / `follow` / `followWithHeading` | `follow` | User-tracking mode |

That's it. The active tile tier is derived from what file is on disk —
the `OfflineMapManager` decides, and it doesn't need to be persisted.

## 9. Requirement additions (append to `requirements.md`)

### 1.8 Offline Map

- **FR-1.8.1** The app shall provide an offline map view accessible from the
  dashboard toolbar.
- **FR-1.8.2** The map shall render worldwide coverage without a network
  connection using a bundled built-in tile pack (z0–z3).
- **FR-1.8.3** The map shall support pinch zoom, pan, and rotate.
- **FR-1.8.4** The map shall display the user's current location, and
  support Off / Follow / Follow-with-heading tracking modes.
- **FR-1.8.5** The user shall be able to download one of several whole-globe
  tile packs (Standard, Detailed) at increasing detail levels for offline
  use, with a size estimate shown before starting and a progress indicator
  during download.
- **FR-1.8.6** The user shall be able to delete the downloaded tile pack,
  reverting to the bundled built-in pack. At most one downloaded pack is
  stored at a time.
- **FR-1.8.7** The map view shall display OpenStreetMap attribution visibly.

### Non-functional

- **NFR-2.4.6** An active tile-pack download shall be cancelled when the app
  enters the background.

## 10. Testing plan

### Unit

- `MapTileTier` — zoom-range mapping, filename derivation.
- `MBTilesStore` — reading a small fixture `.mbtiles`, TMS y-flip handling,
  returns `nil` for missing tiles, closes cleanly.
- `OfflineMapManager` — tier selection, cache-size formatting, mock
  downloader state transitions (idle → downloading → complete / cancelled /
  failed).

### UI (XCTest)

- Navigate from dashboard to map; assert the map view appears.
- With airplane mode: map still renders (built-in pack loaded).

### Manual

- Fresh install, no network, open map → built-in tiles show worldwide.
- Trigger Standard download → progress bar, completion, map gains detail
  when zooming.
- Delete downloaded pack → reverts to built-in.

## 11. Risks & open questions

1. **Tile provider** — real `.mbtiles` URLs must be configured before
   shipping. Placeholder URLs are in `MapTileTier.swift`.
2. **Bundled built-in size** — until a real world-z0–z3 mbtiles is produced
   and added to `Beeflight/Map/Resources/`, the map shows an empty
   background with only the location puck. This is acceptable for initial
   landing and documented in code.
3. **Tile format** — raster PNG. If we later want vector, we can swap the
   overlay implementation without changing the screen / manager surface.
4. **Dark mode** — a second set of dark-style raster tiles would be needed
   for true dark-mode maps. Out of scope for this iteration.

## 12. Implementation order

1. `MBTilesStore` + `MapTileTier` + `OfflineTileOverlay`.
2. `OfflineMapManager` with download / delete / cache-size.
3. `MapView` (UIViewRepresentable) + `OfflineMapScreen`.
4. Dashboard toolbar button + new strings + `mapFollowMode` setting.
5. Tests + docs.
