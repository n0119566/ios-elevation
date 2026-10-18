# Elevation

An offline iOS app that shows your current **elevation** and **coordinates** in big,
bold numbers using only native Apple APIs (SwiftUI + Core Location). No connectivity
required. See [`PLAN.md`](PLAN.md) for the full MVP plan.

## Build & run

The Xcode project is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```sh
# 1. Generate the Xcode project
xcodegen generate

# 2. Build for a simulator
xcodebuild -project Elevation.xcodeproj -scheme Elevation \
  -destination 'platform=iOS Simulator,name=iPhone 17' build

# 3. Or just open it and press Run
open Elevation.xcodeproj
```

On a **real device** you'll see your live GPS elevation (works in Airplane Mode — GPS
needs no network). The Simulator cannot feed altitude through `simctl`, so for UI
verification there's a DEBUG-only launch seam (compiled out of Release):

```sh
xcrun simctl launch booted com.elevation.app -mockLocation 44.2706,-71.3033,1916.6
# → 6,288 ft, 44.2706° N  71.3033° W
```

## Structure

| Path | Role |
|------|------|
| `ElevationApp.swift` | App entry point; owns the `LocationService`. |
| `Models/ElevationReading.swift` | Validated value type (filters invalid altitude). |
| `Services/LocationService.swift` | `@Observable` Core Location wrapper + state machine. |
| `Formatting/Formatters.swift` | Locale-aware elevation / coordinate formatting. |
| `Views/` | `ElevationView` + `BigNumberView` / `CoordinateRow`. |

## Offline guarantee

No `MapKit`, `CLGeocoder`, or `URLSession` anywhere. The compiled binary links only
`CoreLocation` and `SwiftUI` — verifiable with `otool -L`.
