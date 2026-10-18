import CoreLocation
import Foundation

/// A single, validated elevation + coordinate reading.
/// Pure data — no formatting logic lives here.
struct ElevationReading: Equatable {
    let altitudeMeters: Double
    let coordinate: CLLocationCoordinate2D
    let verticalAccuracyMeters: Double
    let horizontalAccuracyMeters: Double
    let timestamp: Date

    /// Build a reading from a Core Location fix.
    /// Returns `nil` when the altitude is invalid (negative vertical accuracy),
    /// so callers never display a bogus value.
    init?(location: CLLocation) {
        guard location.verticalAccuracy >= 0 else { return nil }
        self.altitudeMeters = location.altitude
        self.coordinate = location.coordinate
        self.verticalAccuracyMeters = location.verticalAccuracy
        self.horizontalAccuracyMeters = location.horizontalAccuracy
        self.timestamp = location.timestamp
    }

    static func == (lhs: ElevationReading, rhs: ElevationReading) -> Bool {
        lhs.altitudeMeters == rhs.altitudeMeters &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.verticalAccuracyMeters == rhs.verticalAccuracyMeters &&
        lhs.timestamp == rhs.timestamp
    }
}
