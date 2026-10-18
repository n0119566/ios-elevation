# Elevation — MVP Plan

An offline iOS app that displays your current **elevation** and **coordinates** using
only native Apple APIs. No network connectivity required.

---

## 1. Product scope

### MVP (this plan)
- Show the device's current **elevation** in big, bold, well-formatted numbers.
- Show the current **latitude / longitude** beneath it.
- Work **100% offline** — no network calls, ever.
- Handle location permission + the "acquiring GPS" and "denied" states gracefully.
- Look good: a clean, legible, typographically deliberate single screen.

### Explicitly NOT in the MVP (future iterations)
- Map rendering (MapKit) — deferred.
- Reverse geocoding to get the town/place name — deferred (requires connectivity).
- History, favorites, sharing, widgets, units toggle persistence beyond a simple switch.

> Design the MVP so the elevation/coordinate reading flows through a small view model.
> Later features (map, place name) become additional views that subscribe to the same
> `CLLocation`, not a rewrite.

---

## 2. Why this can be fully offline

Elevation and coordinates come from the device's **GNSS/GPS hardware via Core Location**,
which does not need the internet.

- `CLLocation.coordinate` → latitude & longitude.
- `CLLocation.altitude` → meters above mean sea level (the elevation we display).
- `CLLocation.ellipsoidalAltitude` → meters above the WGS84 ellipsoid (available as a
  secondary/debug value; `altitude` is the right one to show users).
- `CLLocation.verticalAccuracy` → ± meters; if `< 0` the altitude is invalid and we
  should show "—" instead of a bogus number.

The only Apple features that *do* require connectivity are MapKit tiles and
`CLGeocoder` reverse geocoding — both are intentionally out of the MVP.

---

## 3. Tech stack

- **Language:** Swift (latest), **UI:** SwiftUI.
- **Framework:** Core Location (`CLLocationManager`).
- **Minimum iOS:** 17.0 (modern SwiftUI, `@Observable`, `MeasurementFormatter`).
- **Dependencies:** none. Standard library + system frameworks only.
- **Architecture:** MVVM-lite — one `@Observable` location service/view model feeding one SwiftUI view.

---

## 4. Project layout (to be created in this workspace)

```
elevation/
├── PLAN.md                        ← this file
└── Elevation/                     ← Xcode project (created in build step 1)
    ├── Elevation.xcodeproj
    └── Elevation/
        ├── ElevationApp.swift     ← @main App entry point
        ├── Info.plist             ← location usage string
        ├── Models/
        │   └── ElevationReading.swift   ← value type: altitude, coord, accuracy, timestamp
        ├── Services/
        │   └── LocationService.swift    ← @Observable wrapper over CLLocationManager
        ├── Views/
        │   ├── ElevationView.swift      ← main screen
        │   └── Components/
        │       ├── BigNumberView.swift  ← the large bold elevation display
        │       └── CoordinateRow.swift  ← lat/long display
        ├── Formatting/
        │   └── Formatters.swift         ← Measurement/number/coordinate formatting
        └── Assets.xcassets             ← app icon, colors
```

---

## 5. Component responsibilities

### `LocationService` (`@Observable`)
- Owns a single `CLLocationManager`, sets `desiredAccuracy = kCLLocationAccuracyBest`.
- Requests **When In Use** authorization.
- Publishes:
  - `authorizationStatus: CLAuthorizationStatus`
  - `latestReading: ElevationReading?`
  - `state: LocationState` (enum: `.idle`, `.requestingPermission`, `.acquiring`,
    `.active`, `.denied`, `.restricted`, `.unavailable`)
- Implements `CLLocationManagerDelegate`:
  - `locationManagerDidChangeAuthorization` → update status, start/stop updates.
  - `didUpdateLocations` → map newest `CLLocation` → `ElevationReading`, ignore
    readings with `verticalAccuracy < 0`.
  - `didFailWithError` → set an appropriate state (keep last good reading if any).
- No network code. No MapKit import. (Keeps the offline guarantee auditable.)

### `ElevationReading` (value type)
- `altitudeMeters: Double`, `coordinate: CLLocationCoordinate2D`,
  `verticalAccuracyMeters: Double`, `timestamp: Date`.
- Pure data; no formatting logic.

### `Formatters`
- `elevationString(meters:unit:)` using `MeasurementFormatter` so meters↔feet and
  locale grouping (e.g. `1,234 ft`) are correct. Unit chosen from
  `Locale.current.measurementSystem` (US → feet, else meters), with a simple toggle.
- `coordinateString(_:)` → formatted lat/long, e.g. `37.7749° N, 122.4194° W`
  (DMS formatting is a nice-to-have, decimal degrees is the MVP default).

### Views
- **`ElevationView`** — root. Switches on `LocationService.state`:
  - `.acquiring` → subtle progress / "Locating…".
  - `.active` → `BigNumberView` + `CoordinateRow`.
  - `.denied`/`.restricted` → explanation + button to open Settings.
- **`BigNumberView`** — the hero. Large number + unit label.
  - Font: `.system(size:, weight: .bold, design: .rounded)` with
    `monospacedDigit()` so the value doesn't jitter as digits change.
  - Uses `.contentTransition(.numericText())` for smooth value updates.
- **`CoordinateRow`** — lat/long in a smaller, monospaced, secondary-color style.

---

## 6. Typography & visual design (MVP)

- **Elevation number:** SF Pro Rounded, bold, very large (dynamic — scale to width),
  monospaced digits. This is the single focal point of the screen.
- **Unit (`ft`/`m`):** smaller, medium weight, baseline-aligned to the number.
- **Coordinates:** monospaced digits, secondary color, centered under the number.
- **Accuracy hint:** tiny caption, e.g. "± 4 m", tertiary color.
- **Layout:** vertically centered stack on a plain background; respects safe areas and
  Dynamic Type where practical. Supports light & dark mode (system colors).
- **Icon/accent:** a single accent color from the asset catalog.

---

## 7. Permissions / Info.plist

- `NSLocationWhenInUseUsageDescription` — e.g.
  *"Elevation uses your location to show your current altitude and coordinates. It works
  fully offline and never sends your location anywhere."*
- No background modes needed for the MVP (foreground display only).

---

## 8. Build & verification steps

1. **Create the project** in this workspace:
   - Xcode → new iOS App "Elevation" (SwiftUI, Swift), saved under `./Elevation/`.
   - Or scaffold via `xcodegen`/`xcodebuild` if doing it headless.
2. Add the `NSLocationWhenInUseUsageDescription` key.
3. Implement `ElevationReading`, `LocationService`, `Formatters`.
4. Implement `ElevationView` + components; wire `LocationService` as app-level state.
5. **Run on Simulator** with a simulated location (Features → Location → Custom…,
   which includes altitude) to verify the number renders and formats correctly.
6. **Verify offline:** enable Airplane Mode on a *device* (GPS still works) and confirm
   elevation/coordinates still update. (Simulator can't truly prove GPS-offline.)
7. Verify permission flows: first-launch prompt, denied → Settings path.

### Definition of done (MVP)
- [ ] App launches and requests When-In-Use location once.
- [ ] Elevation shows in large bold formatted numbers with correct unit for locale.
- [ ] Latitude/longitude shown and correctly formatted.
- [ ] Works with networking fully disabled (device test).
- [ ] Denied/acquiring states handled without crashing or showing garbage values.
- [ ] No `import MapKit`, no `CLGeocoder`, no `URLSession` anywhere (offline guarantee).

---

## 9. Risks & notes

- **GPS altitude is noisy** (often ± several–tens of meters, worse than horizontal).
  Display `verticalAccuracy` so the number is honest; consider light smoothing later.
- **Simulator altitude** is only available via *custom* simulated locations; the default
  city presets may report 0. Test accordingly.
- **First fix latency** — show the acquiring state; don't render `0` as if it were real.
- **Units toggle** kept minimal in MVP (auto by locale + optional tap-to-switch); full
  settings/persistence is a future iteration.

---

## 10. Future iterations (post-MVP, out of scope here)
1. MapKit snapshot/centered map at the current coordinate (needs connectivity for tiles).
2. Reverse geocoding for town/place name via `CLGeocoder` (needs connectivity) — with an
   offline-first fallback that simply hides the name when no network.
3. Elevation history / high-point tracking, unit persistence, Home Screen widget,
   DMS coordinate format, altitude smoothing/Kalman filter.
