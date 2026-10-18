import CoreLocation
import Foundation

/// Unit the user wants elevation displayed in.
enum ElevationUnit: String, CaseIterable {
    case feet
    case meters

    var unit: UnitLength {
        switch self {
        case .feet: return .feet
        case .meters: return .meters
        }
    }

    var shortLabel: String {
        switch self {
        case .feet: return "ft"
        case .meters: return "m"
        }
    }

    /// Default unit for the current locale (US uses feet, most else meters).
    static var localeDefault: ElevationUnit {
        Locale.current.measurementSystem == .us ? .feet : .meters
    }
}

enum Formatters {
    /// Formatted elevation *number only* (no unit suffix), e.g. "1,234".
    /// The unit is rendered separately so it can be styled distinctly.
    static func elevationValue(meters: Double, unit: ElevationUnit) -> String {
        let measurement = Measurement(value: meters, unit: UnitLength.meters)
        let converted = measurement.converted(to: unit.unit)
        let number = NSNumber(value: converted.value.rounded())

        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 0
        nf.usesGroupingSeparator = true
        return nf.string(from: number) ?? "\(Int(converted.value.rounded()))"
    }

    /// Formatted latitude, e.g. "37.7749° N".
    static func latitude(_ coordinate: CLLocationCoordinate2D) -> String {
        let hemisphere = coordinate.latitude >= 0 ? "N" : "S"
        return String(format: "%.4f° %@", abs(coordinate.latitude), hemisphere)
    }

    /// Formatted longitude, e.g. "122.4194° W".
    static func longitude(_ coordinate: CLLocationCoordinate2D) -> String {
        let hemisphere = coordinate.longitude >= 0 ? "E" : "W"
        return String(format: "%.4f° %@", abs(coordinate.longitude), hemisphere)
    }
}
