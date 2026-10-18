import CoreLocation
import Observation

/// High-level state of the location pipeline, used by the UI to decide what to show.
enum LocationState: Equatable {
    case idle
    case requestingPermission
    case acquiring
    case active
    case denied
    case restricted
    case unavailable
}

/// `@Observable` wrapper over `CLLocationManager`.
///
/// Offline guarantee: this type imports only Core Location + Observation. There is no
/// networking, no MapKit, and no `CLGeocoder` — elevation and coordinates come straight
/// from the GNSS hardware, which works without connectivity.
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    private static let displayUpdateInterval: TimeInterval = 3
    private static let elevationSampleWindow: TimeInterval = 12

    private(set) var authorizationStatus: CLAuthorizationStatus
    private(set) var latestReading: ElevationReading?
    private(set) var state: LocationState = .idle

    @ObservationIgnored private let manager = CLLocationManager()
    @ObservationIgnored private var elevationSamples: [CLLocation] = []
    @ObservationIgnored private var lastDisplayUpdate: Date?

    override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    /// Request permission (once) and begin updates if already allowed.
    func start() {
        #if DEBUG
        // UI-test / preview seam: `-mockLocation lat,lon,altMeters` seeds a reading
        // without the GNSS hardware. Compiled out of Release builds entirely.
        if let mock = LocationService.mockReadingFromLaunchArguments() {
            latestReading = mock
            state = .active
            return
        }
        #endif
        switch authorizationStatus {
        case .notDetermined:
            state = .requestingPermission
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            beginUpdates()
        case .denied:
            state = .denied
        case .restricted:
            state = .restricted
        @unknown default:
            state = .unavailable
        }
    }

    private func beginUpdates() {
        state = latestReading == nil ? .acquiring : .active
        manager.startUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        switch authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            beginUpdates()
        case .denied:
            manager.stopUpdatingLocation()
            state = .denied
        case .restricted:
            manager.stopUpdatingLocation()
            state = .restricted
        case .notDetermined:
            state = .requestingPermission
        @unknown default:
            state = .unavailable
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations where ElevationReading(location: location) != nil {
            elevationSamples.append(location)
        }

        guard let newestLocation = elevationSamples.last else { return }
        elevationSamples.removeAll {
            newestLocation.timestamp.timeIntervalSince($0.timestamp) > Self.elevationSampleWindow
        }

        guard lastDisplayUpdate == nil ||
                newestLocation.timestamp.timeIntervalSince(lastDisplayUpdate!) >= Self.displayUpdateInterval else {
            return
        }

        let altitudes = elevationSamples.map(\.altitude).sorted()
        let medianAltitude = altitudes[altitudes.count / 2]
        let stabilizedLocation = CLLocation(
            coordinate: newestLocation.coordinate,
            altitude: medianAltitude,
            horizontalAccuracy: newestLocation.horizontalAccuracy,
            verticalAccuracy: newestLocation.verticalAccuracy,
            course: newestLocation.course,
            speed: newestLocation.speed,
            timestamp: newestLocation.timestamp
        )
        guard let reading = ElevationReading(location: stabilizedLocation) else { return }

        latestReading = reading
        lastDisplayUpdate = newestLocation.timestamp
        state = .active
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Transient errors (e.g. no fix yet) shouldn't wipe a good reading.
        if latestReading == nil, (error as? CLError)?.code == .denied {
            state = .denied
        }
    }

    #if DEBUG
    private static func mockReadingFromLaunchArguments() -> ElevationReading? {
        let args = ProcessInfo.processInfo.arguments
        guard let idx = args.firstIndex(of: "-mockLocation"), idx + 1 < args.count else {
            return nil
        }
        let parts = args[idx + 1].split(separator: ",").compactMap { Double($0) }
        guard parts.count == 3 else { return nil }
        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: parts[0], longitude: parts[1]),
            altitude: parts[2],
            horizontalAccuracy: 5,
            verticalAccuracy: 4,
            course: 0,
            speed: 0,
            timestamp: Date()
        )
        return ElevationReading(location: location)
    }
    #endif
}
